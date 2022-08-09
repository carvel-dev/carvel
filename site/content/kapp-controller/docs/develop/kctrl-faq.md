## FAQs

 ### How can we add ytt overlays and values schema for upstream release artifacts?
 Overlays can be created in a separate folder in the project directory. `kctrl` can be made aware of any additional folders by updating `package-build.yml` manually,
 If the project directory looks something like this,
 ```bash
 .
 ├── package-build.yml
 ├── package-resources.yml
 ├── upstream
 │   └── cert-manager.yaml
 ├── overlays
 │   └── overlay.yaml
 │   └── values-schema.yaml
 ├── vendir.lock.yml
 └── vendir.yml
 ```
 Where, the directory overlays containing `ytt` is created by the user. The fields `includePaths` and the `template` section of the App `spec` needs to be updated in `package-build.yml` like this,
 ```
 apiVersion: kctrl.carvel.dev/v1alpha1
 kind: PackageBuild
 metadata:
   name: certmanager.carvel.dev
 spec:
   release:
   - resource: {}
   template:
     spec:
       app:
         spec:
           deploy:
           - kapp: {}
           template:
           - ytt:
               paths:
               - upstream
               - overlays   # <= addition to package template
           - kbld: {}
       export:
       - imgpkgBundle:
           image: 100mik/certman-carvel-package
           useKbldImagesLock: true
         includePaths:
         - upstream
         - overlays    # <= ensure additional files are included in imgpkg bundle
 ```
 This is to ensure that the package is aware of the additional files, while `includePaths` ensures that the folder is a part of the `imgpkg` bundle created by `kctrl`.

 The template section in `package-resources.yml` should be updated in a similar fashion to ensure that `kctrl dev deploy` yields similar results.

 `kctrl` generates the OpenAPI schema for a package if a values schema is provided.

 ### How can packages be tested without releasing them?
 `kctrl` creates "mock" Package and PackageMetadata resources in the file `package-resources.yml`. This enables users to run `kctrl dev deploy` to deploy resources a package installation would create without having to release the package or installing `kapp-controller` on the cluster.

 ### Can `kctrl` be used to publish packages in a CI pipeline?
 Yes! `kctrl` remembers the answers to questions that have been answered.
 The `--yes` flag can be used to run the `release` command while using previously supplied
 values if `package-resources.yml` and `package-build.yml` are committed to a repository with the source code.