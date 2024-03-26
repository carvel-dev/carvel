---
title: "Dependency Resolution in KC"
authors: [  "Joao Pereira <joaod@vmware.com>", "Praveen Rewar <prewar@vmware.com>" ]
status: "In Review"
approvers: [ "Dmitriy Kalinin <dkalinin@vmware.com>" ]
---

# Dependency Resolution

## Problem Statement

kapp-controller is being used in many contexts to deploy applications that users want to have in their clusters. One main problem that was never addressed was how can a user install multiple packages or even how can a user say that a particular package needs other packages or resources to be present in the cluster in order for it to work.

The primary way this was being accomplished today was to create a Package that was able to create PackageInstalls for these other Packages, since kapp-controller does not do any validation of the resources that are being installed in the cluster. We believe that this method is effective when the package author is responsible for packaging all these other package, but in a world where we can have multiple package authors and each one of them only manages a subset of these packages we need a better solution.

In this proposal we are going to propose some changes to the Packaging API that will allow the Package Authors to reference other Packages that they depend on as well as expand the API in a way that would allow them to be even more generic, by creating dependencies on the APIs present in the cluster.

## Terminology / Concepts
*GVK* - Group Version Kind, it is a way in Kubernetes to define a particular API

## Proposal
In this proposal we will describe the changes that are necessary to enable the Packaging API to support dependency management.

### Goals and Non-goals

#### Goals
- Evolve the current Packaging API to support dependency management.

#### Non-goals
- Define implementation details

### Specification / Use Cases
In order to achieve above goals, we will make the following changes to the Package and PackageInstall API.

Updated Package API
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: internalpackages.internal.packaging.carvel.dev
spec:
  group: internal.packaging.carvel.dev
  names:
    kind: InternalPackage
    listKind: InternalPackageList
    plural: internalpackages
    singular: internalpackage
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          ...
          spec:
            properties:
              ...
              installationType:
                description: Different types of installation available.
                type: string
                enum:
                  - onePerCluster
                  - onePerNamespace
                  - noRestrictions
                default: noRestrictions
              dependencies: 
                description: Dependencies list of all the dependencies of the current package
                items: &dependencies
                  description: Dependency contains the possible dependencies restrictions
                  properties:
                    name:
                      description: Name of the dependency
                      type: string
                    gvk:
                      description: GVK contains the version of an API that the Package depends on
                      properties:
                        apiVersion:
                          description: APIVersion contains group and version of the API
                          type: string
                        kind:
                          description: Kind contains the kind of the API
                          type: string
                      required:
                      - apiVersion
                      - kind
                      type: object
                    packageRef:
                      description: packageRef contains the reference to the package that should be installed
                      properties:
                        refName:
                          type: string
                        versionSelection:
                          properties:
                            constraints:
                              type: string
                            prereleases:
                                properties:
                                  identifiers:
                                    items:
                                      type: string
                                    type: array
                                type: object
                            type: object
                        type: object
                      type: object
                  required:
                  - name  
                  type: object
                type: array
              provides:
                description: List of GVKs that this Package provides
                items:
                  description: GVK API provided
                  properties:
                    apiVersion:
                      description: APIVersion contains group and version of the API
                      type: string
                    kind:
                      description: Kind contains the kind of the API
                      type: string
                  required:
                  - apiVersion
                  - kind
                  type: object
                type: array

... snip ...                
```

Updated PackageInstall API
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: packageinstalls.packaging.carvel.dev
spec:
  group: packaging.carvel.dev
  names:
    categories:
    - carvel
    kind: PackageInstall
    listKind: PackageInstallList
    plural: packageinstalls
    shortNames:
    - pkgi
    singular: packageinstall
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        description: A Package Install is an actual installation of a package and its underlying resources on a Kubernetes cluster. It is represented in kapp-controller by a PackageInstall CR. A PackageInstall CR must reference a Package CR.
        properties:
          ...
          spec:
            properties:
              ...
              dependencies:
                description: Dependencies that need overrides
                properties:
                  managedBy:
                    default: Auto
                    description: When install is set to User it will only validate the presence of the dependencies, when set to Auto it will try to install/update the Packages
                    enum: 
                    - Auto
                    - User
                    type: string
                  override:
                    description: Override the versions of packages to be installed
                    items:
                      properties:
                        name:
                          description: Name of the dependency
                          type: string
                        packageRef:
                          refName:
                            type: string
                          versionSelection:
                            properties:
                              constraints:
                                type: string
                              prereleases:
                                properties:
                                  identifiers:
                                    items:
                                      type: string
                                    type: array
                                type: object
                            type: object
                        required:
                        - name
                        - packageRef
                        type: object
                    type: array
                  values:
                    description: List of secrets that contain values that will be used for package to be installed, only needed if Packages should be installed
                    items:
                      properties:
                        name:
                          description: Name of the dependency
                          type: string
                        secretRef:
                          description: Reference to the secret
                          properties:
                            name:
                              type: string
                              description: Name of the secret in the same namespace
                          type: object
                      required:
                      - name
                      - secretRef
                      type: object
                    type: array
                type: object

... snip ...

          status:
            properties:
              ... snip ...
              dependencies:
                description: Array with all the fullfilled dependencies information
                items:
                  properties:
                    name:
                      description: Name of the dependency
                      type: string
                    wantedPackageRef:
                      description: WantedPackageRef contains the reference to the package that should be installed
                      properties:
                        refName:
                          type: string
                        versionSelection:
                          properties:
                            constraints:
                              type: string
                            prereleases:
                                properties:
                                  identifiers:
                                    items:
                                      type: string
                                    type: array
                                type: object
                            type: object
                        type: object
                      type: object
                    gvk:
                      description: GVK contains the version of an API that the Package depends on
                      properties:
                        apiVersion:
                          description: APIVersion contains group and version of the API
                          type: string
                        kind:
                          description: Kind contains the kind of the API
                          type: string
                      type: object
                    packageInstallRef:
                      description: PackageInstallRef contains the reference to the installed dependency package
                      properties:
                        name:
                          description: Name of the PackageInstall
                          type: string
                        namespace:
                          description: Namespace of the PackageInstall
                      type: object 
                    conditions:
                      items:
                        properties:
                          message:
                            description: Human-readable message indicating details about a dependency.
                            type: string
                          reason:
                            description: Unique, this should be a short, machine understandable string that gives the reason for condition's last transition.
                            type: string
                          status:
                            type: string
                          type:
                            description: ConditionType represents reconciler state
                            type: string
                        required:
                        - type
                        type: object
                      type: array
                type: array
```

Package Example:
```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: pkg.test.carvel.dev.1.0.0
spec:
  refName: pkg.test.carvel.dev
  version: 1.0.0
  installationType: OnePerCluster 
  dependencies: 
    - name: dep1
      packageRef:
        refName: pkg1.test.carvel.dev
        versionSelection:
          constraints: ~>1.0.0
    - name: dep2
      gvk: 
        apiVersion: some.api.com/v1
        kind: MainApi
    - name: dep3
      packageRef:
        refName: pkg3.test.carvel.dev
        versionSelection:
          constraints: 0.1.0
    - name: dep4
      packageRef:
        refName: pkg4.test.carvel.dev
        versionSelection:
          constraints: 0.2.0
    - name: microservice-v2
      packageRef:
        refName: pkg5.test.carvel.dev
        versionSelection:
          constraints: 0.2.0
    - name: microservice-v1
      packageRef:
        refName: pkg5.test.carvel.dev
        versionSelection:
          constraints: 0.1.0
  
  template: ... # not required when dependencies are specified, but can be included

...

```

PackageInstall Example:
```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: pkg-demo
spec:
  serviceAccountName: pkg-demo-sa
  packageRef:
    refName: pkg.test.carvel.dev
    versionSelection:
      constraints: 1.0.0
  values: # existing
  - ...
  dependencies:
    # the default will be Auto to lessen the burden to the user
    # that is installing a Package. The main use case for Manual would be
    # if the user does not have access to directly install some dependencies
    # or this is the responsibility of other user
    managedBy: Auto  # optional
    override:
      - name: dep1
        packageRef:
          versionSelection:
            contraints: 1.0.1
    values:
      - name: dep1
        secretRef:
          name: pkg1.dev-values
      - name: dep3
        secretRef:
          name: pkg3.dev-values
      - name: microservice-v1
        secretRef:
          name: microservice-v2.dev-values
status:
  version: "..." # existing
  lastAttemptedVersion: "..." # existing

  # the following list of dependencies has 1 item for
  # each dependency defined in the package
  # the name of the PackageInstall will contain a prefix + a random string.
  dependencies:
    - name: dep1
      wantedPackageRef:
        refName: pkg1.test.carvel.dev
        versionSelection:
          constraints: "1.0.1"
      packageInstallRef:
        name: pkg-demo.pkg1.test.carvel.dev
        namespace: default
      conditions:
      - type: OwnedPackageInstall

    - name: dep2
      gvk: 
        apiVersion: some.api.com/v1
        kind: MainApi
      conditions:
      - type: ExistingGVK

    - name: dep3
      wantedPackageRef:
        refName: pkg1.test.carvel.dev
        versionSelection:
          constraints: "1.0.1"
      packageInstallRef: 
        name: name: dep-pkgi.this-is-a-random-string
        namespace: default
      conditions:
      - type: OwnedPackageInstall

    - name: dep4
      wantedPackageRef:
        refName: pkg4.test.carvel.dev
        versionSelection:
          constraints: 0.2.0
      packageInstallRef: 
        name: dep-pkgi.this-is-another-random-string
        namespace: default
      conditions:
      - type: OwnedPackageInstall

    - name: microservice-v1
      wantedPackageRef:
        refName: pkg5.test.carvel.dev
        versionSelection:
          constraints: 0.2.0
      packageInstallRef:
        name: other-pkg.pkg5.test.carvel.dev
        namespace: ns1
      conditions:
      - type: FoundPackageInstall

    - name: microservice-v2
      wantedPackageRef:
        refName: pkg5.test.carvel.dev
        versionSelection:
          constraints: 0.2.0
      packageInstallRef:
        name: pkg-demo.microservice-v2
        namespace: default
      conditions:
      - type: OwnedPackageInstall

    - name: optional-dependency
      wantedPackageRef:
        refName: pkg6.test.carvel.dev
        versionSelection:
          constraints: 0.6.0
      conditions:
      - type: UnknownPackage

    - name: dep-with-wrong-version
      wantedPackageRef:
        refName: pkg1.test.carvel.dev
        versionSelection:
          constraints: "1.0.1" # one on the cluster is 0.1.1
      packageInstallRef:
        name: pkg-demo.pkg1.test.carvel.dev
      conditions:
      - type: FoundPackageInstall
      - type: FoundPackageInstallRequiresDifferentVersion

    - name: dep-with-unknown-package
      wantedPackageRef:
        refName: pkg1.test.carvel.dev
      conditions:
      - type: UnknownPackage

    - name: dep-with-package-with-high-version
      wantedPackageRef:
        refName: pkg1.test.carvel.dev
        versionSelection:
          constraints: ">4.0.0" # cant calculate exact version in this system
      conditions:
      - type: UnknownPackageVersion

```

Example of a PackageInstall that is automatically created
```yaml
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: pkg1.test.carvel.dev.1.0.1
  annotations:
    kapp-controller.carvel.dev/owner: "PackageInstall/pkg-demo"
spec:
    serviceAccountName: pkg-demo-sa
  packageRef:
    refName: pkg3.test.carvel.dev
    versionSelection:
      constraints: 1.0.0
  values:
    secretRef:
      name: pkg3.dev-values
...
```

#### Dependency resolution
The dependency resolution will be done one PackageInstall at a time, basically each PackageInstall will only create the PackageInstalls that it directly depends on.

ex:
```
When pkg depends on pkg1 and pkg3, while pkg1 depends on pkg2
kapp-controller when it is processing pkg it will only
create PackageInstalls for pkg1 and pkg3. In this case pkg2
would be owned by pkg1.

pkg
  -> pkg1
      -> pkg2
  -> pkg3
```

#### Use Cases
##### Package depends on another Package
- When the Package that match the dependency is already installed, no new installation is needed
- When the dependent Package is not installed, it will try to install it
- When a dependent Package is already installed but the version does not fullfil the requirements of the current PackageInstall, kapp-controller will try to install the version that matches
- When there is no Package that fullfills the dependency of a PackageInstall the installation will fail

##### Two Packages depend on the same Package
In this scenario the first PackageInstall that creates the dependent PackageInstall will own it. This means that the second PackageInstall will not need to create the dependent PackageInstall

#### Deletion of PackageInstalls
When a PackageInstall which was responsible for installing one or more dependencies is removed, we will just orphan the dependent package installs (i.e remove the "kapp-controller.carvel.dev/owner" annotation) and not delete them.

#### Future explorations
##### Alternative dependency resolution
Each package would be responsible for creating all the PackageInstall that it depends on as well as all the PackageInstalls that the dependencies might depend on

ex:
```
When pkg depends on pkg1 and pkg3, while pkg1 depends on pkg2
kapp-controller when it is processing pkg it will 
create PackageInstalls for pkg1, pkg2 and, pkg3.

pkg
  -> pkg1
      -> pkg2
  -> pkg3
```

##### Automatic search and installation of packages
In case of gvk dependencies or other dependencies that we can create in the future it is possible for a package to automatically find a Package that could provide the needed functionality.
```yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: some-pkg.test.carvel.dev.1.0.0
spec:
  refName: some-pkg.test.carvel.dev
  version: 1.0.0
  dependencies:
    - gvk:
        group: api.carvel.dev
        kind: Resource
        version: v1
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: provider.carvel.dev.1.0.0
spec:
  refName: provider.carvel.dev
  version: 1.0.0
  provides:
    - gvk:
        apiVersion: api.carvel.dev/v1
        kind: Resource
```
In the example above the author of the `some-pkg.test.carvel.dev` does not have to specify a particular Package to install because kapp-controller would be able to automatically find and install the needed package

##### Force deletion of dependent packages
When creating a PackageInstall the user can define if they want to delete the dependent packages when the current PackageInstall is removed.

##### Synchronous Installation of Dependencies
When creating a PackageInstall, it will first wait for the dependencies to get installed and the current PackageInstall will be in a WaitingForDependencies state. Once the dependencies are installed, it will move to Reconciling state.

##### Enforce dependent PackageInstall cannot be modified
The current proposal assume that by convension the PackageInstalls created by kapp-controller should not be updated. Nevertheless we can explore the possibility of creating a webhook that will enforce this behavior.

### kctrl
We will make relavant changes in kctrl for users to be able to view and install dependent packages when installing packages via the cli.

#### kctrl package available get
The package available get command would provide a list of gvks and packages that the current package is dependent upon.

```bash
$ kctrl package available get -p pkg.test.carvel.dev/1.0.0
Target cluster 'https://192.168.64.27:8443' (nodes: minikube)

Name                       pkg.test.carvel.dev
Display name               Carvel Test Package

... snip ...

Licenses                   Apache 2.0
Dependencies               - name: dep1
                           - packageRef:
                           -   refName: pkg1.test.carvel.dev
                           -   versionSelection:
                           -     constraints: 1.0.0
```

#### kctrl package install

```bash
$ kctrl package install -i sample-pkg-install -p package.corp.com --version 1.0.0 --override:dep-1='{"versionSelection": {"constraints": 1.0.1}}' --values-file=values-file-for-all.yaml

# where values-file-for-all.yaml contains values file for the PackageInstall and one or all of it's dependencies, ex

---
app_port: 8080
hello_msg: stranger

---
# dep=dep-1               # key = dep, value = name of dependency
svc_port: 80
```


### Other Approaches Considered
_Mention of other reasonable ways that the problem(s)
could be addressed with rationale for why they were less
desirable than the proposed approach._

## Open Questions

- What happens if the Resource did not change version but new fields were added and the package requires them but that version of the Resource is not present in the cluster?

## Answered Questions
_A list of questions that have been answered._