---
aliases: [/kapp-controller/docs/latest/install]
title: Install
---

Grab the latest copy of YAML from the [Releases page](https://github.com/carvel-dev/kapp-controller/releases) and use your favorite deployment tool (such as [kapp](/kapp) or kubectl) to install it.

Example:

```bash
$ kapp deploy -a kc -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

or

```bash
$ kubectl apply -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

## Specific Environments and Distributions
Some kubernetes distributions require specific setup.
Notes below capture the wisdom of our collective community - we
appreciate your corrections and contributions to help everyone install
kapp-controller everywhere.

### Openshift

1. Explicitly set resource packageinstalls/finalizers for kapp controller cluster role to access (else the kapp controller fails to create packageinstalls).

    ```
    kind: ClusterRole
    metadata:
      name: kapp-controller-cluster-role
    rules:
    - apiGroups:
      - packaging.carvel.dev
      resources:
      ...
      - packageinstalls/finalizers
    ```

2. Bind the kapp-controller cluster role to a security context constraint allowing uids/gids that kapp deployment uses
(currently uid 1000; value given for `runAsUser` in the release.yaml for your
version of kapp-controller).

    **Note:** The security context constraint you provide should allow kapp-controller's uid
    to run and should not have root privileges.

    ```
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: kapp-controller-cluster-role
    rules:
    - apiGroups:
      - security.openshift.io
      resourceNames:
      - my-nonroot-security-context-contstraint
      resources:
      - securitycontextconstraints
      verbs:
      - use
    ```

3. Remove the environment variable `IMGPKG_ACTIVE_KEYCHAINS` [environment
   variable](/imgpkg/docs/latest/auth/#via-iaas) from the deployment yaml of the sidecar container.


### Kubernetes versions >= 1.24
All kapp-controller versions <= v0.36.1 will be unable to reconcile
PackageInstall and App CRs with the `LegacyServiceAccountTokenNoAutoGeneration`
feature gate, which is enabled by default in Kubernetes starting in v1.24.

### Kubernetes versions < 1.20
Starting in kapp-controller 0.31.0 we have upgraded our underlying kubernetes
libraries which will try to use APIs that don't exist on clusters v1.19 and
earlier.

Those using k8s v1.19 and earlier will see a repeating error message such as the one below, because
our libraries are hardcoded to watch `v1beta1.PriorityLevelConfiguration` and that won't exist on your cluster.
```
k8s.io/client-go@v0.22.4/tools/cache/reflector.go:167: Failed to watch *v1beta1.PriorityLevelConfiguration: failed to list *v1beta1.PriorityLevelConfiguration: the server could not find the requested resource (get prioritylevelconfigurations.flowcontrol.apiserver.k8s.io)
```
While kapp-controller will still work, your logs may fill at a remarkable pace.

To disable these APIs, set the deployment config variable
`enable_api_priority_and_fairness` to false.

### Installing kapp-controller CLI: kctrl

#### Via script (macOS or Linux)

(Note that `install.sh` script installs other Carvel tools as well.)

Install binaries into specific directory:

```bash
$ mkdir local-bin/
$ curl -L https://carvel.dev/install.sh | K14SIO_INSTALL_BIN_DIR=local-bin bash

$ export PATH=$PWD/local-bin/:$PATH
$ kctrl version
```

Or system wide:

```bash
$ wget -O- https://carvel.dev/install.sh > install.sh

# Inspect install.sh before running...
$ sudo bash install.sh
$ kctrl version
```

#### Via Homebrew (macOS or Linux)

Based on [github.com/carvel-dev/homebrew](https://github.com/carvel-dev/homebrew).

```bash
$ brew tap carvel-dev/carvel
$ brew install kctrl
$ kctrl version
```

#### Specific version from a GitHub release

To download, click on one of the assets in a [chosen GitHub release](https://github.com/carvel-dev/kapp-controller/releases), for example for 'kctrl-darwin-amd64'.

```bash
# **Compare binary checksum** against what's specified in the release notes
# (if checksums do not match, binary was not successfully downloaded)
$ shasum -a 256 ~/Downloads/kctrl-darwin-amd64
08b25d21675fdc77d4281c9bb74b5b36710cc091f30552830604459512f5744c  /Users/pivotal/Downloads/kctrl-darwin-amd64

# Move binary next to your other executables
$ mv ~/Downloads/kctrl-darwin-amd64 /usr/local/bin/kctrl

# Make binary executable
$ chmod +x /usr/local/bin/kctrl

# Check its version
$ kctrl version
```
