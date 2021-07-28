## Creating the Custom Resources

To finish creating a package, we need to create two CRs. The first CR is the PackageMetadata CR, which will contain high level information and descriptions about our package.

When creating this CR, the api will validate that the PackageMetadata’s name is a fully qualified name: It must have at least three segments separated by `.` and cannot have a trailing `.`.

We'll make a conformant `metadata.yml` file:

```
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

```
cat > 1.0.0.yml << EOF
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: simple-app.corp.com.1.0.0
spec:
  refName: simple-app.corp.com
  version: 1.0.0
  releaseNotes: |
        Initial release of the simple app package
  valuesSchema:
    openAPIv3:
      title: simple-app.corp.com values schema
      examples:
      - svc_port: 80
        app_port: 80
        hello_msg: stranger
      properties:
        svc_port:
          type: integer
          description: Port number for the service.
          default: 80
          examples:
          - 80
        app_port:
          type: integer
          description: Target port for the application.
          default: 80
          examples:
          - 80
        hello_msg:
          type: string
          description: Name used in hello message from app when app is pinged.
          default: stranger
          examples:
          - stranger
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: ${REPO_HOST}/packages/simple-app:1.0.0
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

This Package contains some metadata fields specific to the verison, such as releaseNotes and a valuesSchema. The valuesSchema shows what configurable properties exist for the version. This will help when users want to install this package and want to know what can be configured.

The other main component of this CR is the template section.
This section informs kapp-controller of the actions required to install the packaged software, so take a look at the [app-spec](https://carvel.dev/kapp-controller/docs/latest/app-spec/) section to learn more about each of the template sections. For this example, we have chosen a basic setup that will fetch the imgpkg bundle we created in the previous section, run the templates stored inside through ytt, apply kbld transformations, and then deploy the resulting manifests with kapp.

There will also be validations run on the Package CR, so ensure that spec.refName and spec.version are not empty and that metadata.name is `<spec.refName>.<spec.version>`.
These validations are done to encourage a naming scheme that keeps package version names unique.
