---

title: App CR spec
---

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App

metadata:
  name: simple-app
  # namespace is going to be used as a default namespace during kapp deploy
  namespace: ns

spec:
  # pauses _future_ reconcilation; does _not_ affect
  # currently running reconciliation (optional; default=false)
  paused: true

  # cancels current and future reconciliations (optional; default=false)
  canceled: true

  # Deletion requests for the App will result in the App CR being
  # deleted, but its associated resources will not be deleted
  # (optional; default=false; v0.18.0+)
  noopDelete: true

  # specifies that app should be deployed authenticated via
  # given service account, found in this namespace (optional; v0.6.0+)
  serviceAccountName: sa-name

  # specifies the length of time to wait, in time + unit
  # format, before reconciling. Always >= 30s. If value below
  # 30s is specified, 30s will be used. (optional; v0.9.0+; default=30s)
  syncPeriod: 1m

  # specifies that app should be deployed to destination cluster;
  # by default, cluster is same as where this resource resides (optional; v0.5.0+)
  cluster:
    # specifies kapp namespace in destination cluster (optional)
    # see {{< ref "/kapp/docs/v0.44.0/state-namespace" >}}
    namespace: ns2
    # specifies secret containing kubeconfig (required)
    kubeconfigSecretRef:
      # specifies secret name within app's namespace (required)
      name: cluster1
      # specifies key that contains kubeconfig (optional)
      key: value

  # Fetch must have one or more directives
  fetch:
    # pull content from within this resource; or other resources in the cluster
    - inline:
        # specifies mapping of paths to their content;
        # not recommended for sensitive values as CR is not encrypted (optional)
        paths:
          dir/file.ext: file-content
        # specifies content via secrets and config maps;
        # data values are recommended to be placed in secrets (optional)
        pathsFrom:
          - secretRef:
              name: secret-name
              # specifies where to place files found in secret (optional)
              directoryPath: dir
          - configMapRef:
              name: cfgmap-name
              # specifies where to place files found in config map (optional)
              directoryPath: dir

    # pulls content from Docker/OCI registry
    - image:
        # Docker image url; unqualified, tagged, or
        # digest references supported (required)
        url: host.com/username/image:v0.1.0
        # secret with auth details (optional)
        secretRef:
          name: secret-name
        # grab only portion of image (optional)
        subPath: inside-dir/dir2
        # specifies a strategy to choose a tag (optional; v0.24.0+)
        # if specified, do not include a tag in url key
        tagSelection:
          semver:
            # list of semver constraints (required)
            constraints: ">1.0.0 <3.0.0"
            # by default prerelease versions are not included (optional; v0.24.0+)
            prereleases:
              # select prerelease versions that include given identifiers (optional; v0.24.0+)
              identifiers: [beta, rc]

    # pulls imgpkg bundle from Docker/OCI registry (v0.17.0+)
    - imgpkgBundle:
        # Docker image url; unqualified, tagged, or
        # digest references supported (required)
        image: host.com/username/image:v0.1.0
        # secret with auth details (optional)
        secretRef:
          name: secret-name
        # specifies a strategy to choose a tag (optional; v0.24.0+)
        # if specified, do not include a tag in url key
        tagSelection:
          semver:
            # list of semver constraints (see https://carvel.dev/vendir/docs/latest/versions/ for details) (required)
            constraints: ">1.0.0 <3.0.0"
            # by default prerelease versions are not included (optional; v0.24.0+)
            prereleases:
              # select prerelease versions that include given identifiers (optional; v0.24.0+)
              identifiers: [beta, rc]

    # uses http library to fetch file
    - http:
        # http and https url are supported;
        # plain file, tgz and tar types are supported (required)
        url: https://host.com/archive.tgz
        # checksum to verify after download (optional)
        sha256: 0a12cdef83...
        # secret to provide auth details (optional)
        secretRef:
          name: secret-name
        # grab only portion of download (optional)
        subPath: inside-dir/dir2

    # uses git to clone repository
    - git:
        # http or ssh urls are supported (required)
        url: https://github.com/k14s/k8s-simple-app-example
        # branch, tag, commit; origin is the name of the remote (required)
        ref: origin/develop
        # secret with auth details. allowed keys: ssh-privatekey, ssh-knownhosts, username, password (optional)
        # (if ssh-knownhosts is not specified, git will not perform strict host checking)
        secretRef:
          name: secret-name
        # grab only portion of repository (optional)
        subPath: config-step-2-template
        # skip lfs download (optional)
        lfsSkipSmudge: true
        # specifies a strategy to resolve to an explicit ref (optional; v0.24.0+)
        refSelection:
          semver:
            # list of semver constraints (see https://carvel.dev/vendir/docs/latest/versions/ for details) (required)
            constraints: ">0.4.0"
            # by default prerelease versions are not included (optional; v0.24.0+)
            prereleases:
              # select prerelease versions that include given identifiers (optional; v0.24.0+)
              identifiers: [beta, rc]

    # uses helm fetch to fetch specified chart
    - helmChart:
        name: stable/nginx
        # (optional)
        version: "0.1.0"
        # (optional)
        repository:
          # repository url;
          # scheme of oci:// will fetch experimental helm oci chart (v0.19.0+)
          # (required)
          url: https://...
          # (optional)
          secretRef:
            name: secret-name

  # Template must have one or more directives
  template:
    # use ytt to template configuration
    - ytt:
        # ignores comments that ytt doesn't recognize
        # (optional; default=false)
        ignoreUnknownComments: true
        # forces strict mode https://github.com/k14s/ytt/blob/develop/docs/strict.md
        # (optional; default=false)
        strict: true
        # specify additional files, including data values (optional)
        inline:
          # specifies content inline within resource;
          # not recommended for sensitive values as CR is not encrypted (optional)
          paths:
            # mapping of paths to their content
            dir/file.ext: |
              file-content
              file-content
          # specified content via secrets and config maps;
          # data values are recommended to be placed in secrets (optional)
          pathsFrom:
            - secretRef:
                name: secret-name
                # specifies where to place files found in secret (optional)
                directoryPath: dir
            - configMapRef:
                name: cfgmap-name
                # specifies where to place files found in config map (optional)
                directoryPath: dir
        # lists paths to provide to ytt explicitly (optional)
        paths:
        # - must be quoted when included with paths
        - "-"
        - dir/common
        - dir/nested/app
        # control metadata about input files passed to ytt (optional; v0.18.0+)
        # see https://carvel.dev/ytt/docs/latest/file-marks/ for more details
        fileMarks:
        - file-content:type=yaml-plain
        - dir/common/bom**/*:type=text-plain
        - dir/nested/app/file.txt:exclude=true
        - dir/common/generated.go.txt:path=gen.go.txt
        # provide values via ytt's --data-values-file (optional; v0.19.0-alpha.9)
        valuesFrom:
          - secretRef:
              name: secret-name
          - configMapRef:
              name: cfgmap-name
          - path: values/shared.yml

    # use kbld to resolve image references to use digests
    - kbld:
        # lists paths to use explicitly (optional; v0.13.0+)
        # - must be quoted when included with paths
        paths:
        - .imgpkg/images.yml
        - "-"

    # use helm template command to render helm chart
    - helmTemplate:
        # path to chart (optional; v0.13.0+)
        path: some-chart/
        # set name explicitly, default is App CR's name (optional; v0.13.0+)
        name: custom-name
        # set namespace explicitly, default is App CR's namespace (optional; v0.13.0+)
        namespace: custom-ns
        # one or more secrets, config maps, paths that provide values (optional)
        valuesFrom:
          - secretRef:
              name: secret-name
          - configMapRef:
              name: cfgmap-name
          - path: values/shared.yml

    # use sops to decrypt *.sops.yml files (optional; v0.11.0+)
    - sops:
        # use PGP to decrypt files (required)
        pgp:
          # secret with private armored PGP private keys (required)
          privateKeysSecretRef:
            # (required)
            name: pgp-secrets
        # lists paths to decrypt explicitly (optional; v0.13.0+)
        paths:
        - all-secrets/
        - prod-secrets/prod.sops.yml

  # Deploy must have one directive
  deploy:
    # use kapp to deploy resources
    - kapp:
        # override namespace for all resources (optional)
        intoNs: another-ns1
        # provide custom namespace override mapping (optional)
        mapNs: ["ns1=another-ns1"]
        # pass through options to kapp deploy (optional)
        rawOptions: ["--apply-concurrency=10"]
        # configuration for inspect command (optional)
        # as of kapp-controller v0.31.0, inspect is disabled by default
        # add rawOptions or use an empty inspect config like `inspect: {}` to enable it
        inspect:
          # pass through options to kapp inspect (optional)
          rawOptions: ["--json=true"]
        # configuration for delete command (optional)
        delete:
          # pass through options to kapp delete (optional)
          rawOptions: ["--apply-ignored=true"]

# status is popuated by the controller
status:
  # populated based on metadata.generation when controller
  # observes a change to the resource; if this value is 
  # out of data, other status fields do not reflect latest state
  observedGeneration: 1

  conditions:
    # "Reconciling" indicates that fetch/template/deploy is happening;
    # it does not mean that any resource has changed
    - type: Reconciling
      status: "True"
    # "ReconcileFailed" indicates that one of the stages failed
    - type: ReconcileFailed
      status: "True"
    # "ReconcileSucceeded" indicates that all stages succeeded
    - type: ReconcileSucceeded
      status: "True"

  fetch:
    exitCode: 0
    error: "..."
    stderr: "..."
    startedAt: "2019-11-07T16:37:23Z"
    updatedAt: "2019-11-07T16:37:23Z"

  template:
    exitCode: 0
    error: "..."
    stderr: "..."
    updatedAt: "2019-11-07T16:37:23Z"

  deploy:
    exitCode: 0
    error: "..."
    stderr: "..."
    finished: true
    startedAt: "2019-11-07T16:37:23Z"
    stdout: |-
      Changes
      Namespace  Name  Kind  Conds.  Age  Op  Wait to  Rs  Ri
      Op:      0 create, 0 delete, 0 update, 0 noop
      Wait to: 0 reconcile, 0 delete, 0 noop
      Succeeded
    updatedAt: "2019-11-07T16:37:23Z"

  inspect:
    exitCode: 0
    error: "..."
    stderr: "..."
    stdout: |-
      Resources in app 'simple-app-ctrl'
      Namespace  Name                              Kind        Owner    Conds.  Rs  Ri  Age
      default    simple-app                        Deployment  kapp     2/2 t   ok  -   7d
      default     L simple-app-6b6b4fcd97          ReplicaSet  cluster  -       ok  -   7d
      default     L.. simple-app-6b6b4fcd97-kwclv  Pod         cluster  4/4 t   ok  -   7d
      default    simple-app                        Service     kapp     -       ok  -   7d
      default     L simple-app                     Endpoints   cluster  -       ok  -   7d
      Rs: Reconcile state
      Ri: Reconcile information
      5 resources
      Succeeded
    updatedAt: "2019-11-07T16:37:23Z"
```
