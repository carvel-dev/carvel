#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# How to run the command to generate new documentation of impkg from develop with the version v0.5.0
# ./hack/release-docs.sh imgpkg v0.5.0

TOOL=$1
NEW_VERSION=$2
FROM_VERSION=${3:-develop}

CONTENT_DIRECTORY=content/${TOOL}/docs
TOC_DIRECTORY=data/${TOOL}/docs

# don't run if there's already a directory for the target docs version
if [[ -d $CONTENT_DIRECTORY/$NEW_VERSION ]]; then
    echo "ERROR: $CONTENT_DIRECTORY/$NEW_VERSION already exists"
    exit 1
fi

LATEST_VERSION=$(ytt -f version.yml=<(echo -e "#@ load('@ytt:data', 'data')\n--- #@ data.values.params[\"${TOOL}\"].version_latest") --data-values-file config.yaml)
# don't run if cannot find the origin version
if [[ ! -d $CONTENT_DIRECTORY/$FROM_VERSION ]]; then
    echo "ERROR: $CONTENT_DIRECTORY/$FROM_VERSION from version folder does not exist"
    exit 1
fi

PREVIOUS_VERSION="${LATEST_VERSION}"
COPY_FROM_FOLDER="${CONTENT_DIRECTORY}/${LATEST_VERSION}/"
if [ "${FROM_VERSION}" != "develop" ] && [ "${FROM_VERSION}" != "${LATEST_VERSION}" ]; then
  PREVIOUS_VERSION=$(ytt -f version.yml=<(echo -e "#@ load('@ytt:data', 'data')\n--- #@ data.values.cascade.version") --data-values-file <(head -n8 content/ytt/docs/v0.38.0/_index.md))
  COPY_FROM_FOLDER="${CONTENT_DIRECTORY}/${FROM_VERSION}/"
fi


if [ "${FROM_VERSION}" == "develop" ]; then # When creating a new release from develop
  echo "Copying the content of the develop documentation to latest documentation"
  cp -rf "${CONTENT_DIRECTORY}"/develop "${CONTENT_DIRECTORY}"/${NEW_VERSION}

  echo "Update version on ${NEW_VERSION} docs"
  sed -i.bak "s/version: develop/version: ${NEW_VERSION}/" "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md
  rm "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md.bak
elif [ "${FROM_VERSION}" == "${LATEST_VERSION}" ]; then # When creating a patch from the latest release
    echo "Copying the content of the latest documentation to named version ${LATEST_VERSION}"
    cp -rf "${CONTENT_DIRECTORY}"/${LATEST_VERSION} "${CONTENT_DIRECTORY}"/"${NEW_VERSION}"

    echo "Update version on ${NEW_VERSION} docs"
    sed -i.bak "s/version: ${LATEST_VERSION}/version: ${NEW_VERSION}/" "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md
    rm "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md.bak
else # When creating a patch for any other release
  echo "Copying the content of the ${FROM_VERSION} documentation to named version ${NEW_VERSION}"
  cp -rf "${CONTENT_DIRECTORY}/${FROM_VERSION}/" "${CONTENT_DIRECTORY}"/"${NEW_VERSION}"
  sed -i.bak "s/version: ${FROM_VERSION}/version: ${NEW_VERSION}/" "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md
  rm "${CONTENT_DIRECTORY}"/${NEW_VERSION}/_index.md.bak
fi

dashedVersion=${NEW_VERSION//\./-}
echo "Copy table of content"
cp  "${TOC_DIRECTORY}"/"${TOOL}"-develop-toc.yml "${TOC_DIRECTORY}"/"${TOOL}"-"${dashedVersion}"-toc.yml

currentTOC="${TOC_DIRECTORY}"/toc-mapping.yml

echo "Updating the TOC file"
ytt --ignore-unknown-comments -f"$currentTOC" -ftocOverlay.yml=<(cat <<EOF
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.all
#@overlay/match-child-defaults missing_ok=True
---
${NEW_VERSION}: ${TOOL}-${dashedVersion}-toc
EOF) > /tmp/newToc.yml
mv /tmp/newToc.yml $currentTOC

echo "Updating the configuration file"
if [ "${FROM_VERSION}" == "develop" ] || [ "${FROM_VERSION}" == "${LATEST_VERSION}" ]; then
  echo "For latest version"
  ytt -f config.yaml -fconfigOverlay.yml=<(cat <<EOF
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.all
---
params:
  ${TOOL}:
    latest_docs_link: /${TOOL}/docs/${NEW_VERSION}/
    version_latest: ${NEW_VERSION}
    versions:
    #@overlay/match by=overlay.index(0)
    #@overlay/insert after=True
    - ${NEW_VERSION}
EOF) > /tmp/newConfig.yml
  mv /tmp/newConfig.yml config.yaml

  echo "Add redirection from latest to version ${NEW_VERSION}"
  for file in $(find content/${TOOL}/docs/${NEW_VERSION} -name "*.md");
  do
     filename=$(basename $file)
     if [[ "$filename" == "_index.md" ]]; then
       filename=
     fi

     cat "$file" | awk 'BEGIN {t=0}; { print }; /---/ { t++; if ( t==1) { printf "aliases: [/%s/docs/latest/%s]\n", tool, filename } }' tool=${TOOL} filename="${filename%.md}" > "$file.bak"
     mv "$file".bak "$file"
  done

  echo "Remove redirection from ${LATEST_VERSION} to latest"
  for file in $(find content/${TOOL}/docs/${LATEST_VERSION} -name "*.md");
    do
       sed -i.bak "s/aliases: \[[a-z\/\-]*\]//" $file
       rm "$file.bak"
    done
else
  echo "For patch version version"
  ytt -f config.yaml -fconfigOverlay.yml=<(cat <<EOF
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.all
---
params:
  ${TOOL}:
    versions:
    #@overlay/match by=overlay.subset("${FROM_VERSION}")
    #@overlay/insert before=True
    - ${NEW_VERSION}
EOF) > /tmp/newConfig.yml
  mv /tmp/newConfig.yml config.yaml
fi
