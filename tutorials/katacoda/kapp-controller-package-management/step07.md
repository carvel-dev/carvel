## Creating the Custom Resources

To finish creating a package, we need to create two CRs. The first CR is the PackageMetadata CR, which will contain high level information and descriptions about our package.

When creating this CR, the api will validate that the PackageMetadata’s name is a fully qualified name: It must have at least three segments separated by `.` and cannot have a trailing `.`.

We'll make a conformant `metadata.yml` file:

```bash
cat > metadata.yml << EOF
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  # This will be the name of our package
  name: simple-app.corp.com
spec:
  displayName: "Simple App"
  longDescription: "Simple app consisting of a k8s deployment and service"
  shortDescription: "Simple app for demoing"
  categories:
  - demo
EOF
```{{execute}}

Now we need to create a Package CR.
This CR contains versioned instructions and metadata used to install packaged software that fits the description provided in the PackageMetadata CR we just saved in `metadata.yml`.

In order to create the Package CR with our OpenAPI Schema, we will export from
our ytt schema:

```bash
ytt -f package-contents/config/values.yml --data-values-schema-inspect -o openapi-v3 > schema-openapi.yml
```{{execute}}

That command creates an OpenAPI document, from which we really only need the
`components.schema` section for our Package CR.


```bash
cat > package-template.yml << EOF
#@ load("@ytt:data", "data")  # for reading data values (generated via ytt's data-values-schema-inspect mode).
#@ load("@ytt:yaml", "yaml")  # for dynamically decoding the output of ytt's data-values-schema-inspect
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: #@ "simple-app.corp.com." + data.values.version
spec:
  refName: simple-app.corp.com
  version: #@ data.values.version
  releaseNotes: |
        Initial release of the simple app package
  valuesSchema:
    openAPIv3: #@ yaml.decode(data.values.openapi)["components"]["schemas"]["dataValues"]
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: #@ "${REPO_HOST}/packages/simple-app:" + data.values.version
      template:
      - ytt:
          paths:
          - "config/"
      - kbld:
          paths:
          - "-"
          - ".imgpkg/images.yml"
      deploy:
      - kapp: {}
EOF
```{{execute}}

This Package contains some metadata fields specific to the version, such as releaseNotes and a valuesSchema. The valuesSchema shows what configurable properties exist for the version. This will help when users want to install this package and want to know what can be configured.

The other main component of this CR is the template section.
This section informs kapp-controller of the actions required to install the packaged software, so take a look at the [app-spec](https://carvel.dev/kapp-controller/docs/latest/app-spec/) section to learn more about each of the template sections. For this example, we have chosen a basic setup that will fetch the imgpkg bundle we created in the previous section, run the templates stored inside through ytt, apply kbld transformations, and then deploy the resulting manifests with kapp.

There will also be validations run on the Package CR, so ensure that spec.refName and spec.version are not empty and that metadata.name is `<spec.refName>.<spec.version>`.
These validations are done to encourage a naming scheme that keeps package version names unique.
