---
title: "Packaging APIs + Registry Auth"
authors: [ "Dmitriy Kalinin <dkalinin@vmware.com>" ]
status: "In Review"
approvers: [ "Daniel Helfand <dhelfand@vmware.com>", "Joe Kimmel <jkimmel@vmware.com>" ]
---

# Problem

Some package repository bundles and package bundles are hosted in registries
that require authentication. Users interacting with packaging APIs should have
minimal interaction with registry credentials for the sake of user experience,
so that: only users interacting with package repositories should have to provide
registry credentials users creating PackageInstall CR should not have to think
about registry creds users interacting with CRs installed via a package should
not have to think about registry creds

Why isn't node pre-auth enough? kapp-controller uses imgpkg inside its pod to
communicate with registries and does not have access to full node pre-auth (IaaS
provided node pre-auth is useable since it appears to be served off of IaaS
specific metadata endpoints == does not depend on node filesystem [0]). Node
pre-auth configuration may not be possible on some clusters, and also does not
align well with the lifecycle of package repositories being
added/removed/changed.

[0] https://github.com/google/go-containerregistry/tree/main/pkg/authn/k8schain


# Cases

### User wants to use package which fetches contents from private registry
* User has credentials which allow access private registry
* User adds PackageRepository CR for package to their cluster
* User creates PackageInstall CR to install package on their cluster
* Package is installed successfully

### User wants to use a package which contains an operator and is stored in a private registry
* User has authentication details allowing access to the private registry
* User adds PackageRepository CR for operator package to their cluster
* User creates PackageInstall CR to install operator package on their cluster
* Operator pulls images from private repo

### OSS user wants to use fully public package
* User has a Kubernetes cluster (e.g. GKE, Rancher, OpenShift, etc.)
* User adds PackageRepository CR for their publicly available repo
* User creates PackageInstall CR to install publicly available package on their
  cluster

### Use case breakdown

* Registry access could be authenticated or non-authenticated
  * when access is non-authenticated, packaging APIs do not require any kind of
    additional setup
  * when access is authenticated, packaging APIs would need to have some
    credentialing interaction
* Registry access is needed by:
  * Inside kapp-controller's pod (for imgpkg) to pull package repository bundle
  * Inside kapp-controller's pod (for imgpkg) to pull package bundles
  * CRI for pulling Pod container images as part of package installation (e.g.
    operator image)
  * CRI for pulling Pod container images as part of using operator
  * Knative serving (CNR) resolves tags to digest when creating Revisions, to
    prevent future image changes during autoscaling



# Proposal

## Goals and Non-goals
Goals:
* Provide a way for package authors to make their packages work with or without
  registry auth
* Provide a way for package consumers to easily configure registry auth

Non-goals:
* Future goals
* Support for similar experience for non-Carvel packaged workloads like Helm
  Chart contents

## Details

Provide a way to specify registry credentials once in the cluster and have a way
for various consumers (e.g. packaging APIs, kubernetes for fetching container
images for Pods) be able to access them.  (side note) Since kapp-controller has
a generic fetching mechanism, it supports the ability to fetch package repo and
packages via different mechanisms such as git, http, etc. Example: spec.fetch
section. This means that credentials do not necessarily need to be for a
registry, but could be git repo creds, etc.

## Specification

placeholder secret = k8s Secret with secretgen.carvel.dev/secret-request annotation.

At high level:
* kapp-controller would create placeholder secrets for PackageRepository CRs and
  App CRs created for PackageInstall, if explicit secret is not specified
* install secretgen-controller alongside kapp-controller
* secretgen-controller would watch for placeholder secrets and populate them
  with combined registry creds
* kapp-controller would take into account populated placeholder secrets when
  fetching bundles

Before digging into below example, check out SecretExport and SecretRequest.
This proposal extends that functionality to express SecretRequest via a regular
Kubernetes secret that has specific annotations. For the purpose of this
proposal we are introducing a single "sugared" annotation that solves the case
of image pull secrets. In future, this API could be extended to allow requests
to match based on subject (like git repo url, or registry name) or by type (for
registry creds, multiple creds could be aggregated into a single secret).

```yaml
# ...created once in the cluster somewhere...
---
kind: Secret
metadata:
  name: private-reg-creds
  namespace: shared-creds
type: kubernetes.io/dockerconfigjson
data: {...}
---
# We are extending SecretExport mechanism defined by secretgen-controller
# https://github.com/vmware-tanzu/carvel-secretgen-controller/blob/develop/docs/secret-export.md
kind: SecretExport
metadata:
  name: private-reg-creds # assumes there is a Secret with that name
  namespace: shared-creds
spec:
  toNamespaces: ["*"]

# ...elsewhere in the cluster...

# This placeholder secret will be eventually populated by a secretgen-controller
kind: Secret
metadata:
  name: img-creds
  namespace: anywhere
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30=
```

Placeholder secret above is found by the secretgen-controller due to its
annotation. secretgen-controller would find all matching exported secrets of
type "kubernetes.io/dockerconfigjson" and combine their contents together into a
single value that would be saved into this placeholder secret.

k8s Secret with annotation is used as an API (instead of a dedicated CR) to
allow users of such API work on clusters that have and do not have
secretgen-controller installed. This provides a loose coupling.

# Examination

## Implications
* (security) We are making an assumption that it's ok for any user on the
  cluster to have access to exported registry credentials. This should be ok
  because registry credentials should be read-only.
* (limitation) Single Kubernetes secret (of type kubernetes.io/dockerconfigjson)
  cannot contain multiple different credentials for the same registry. Which
  means that if a single Pod has multiple containers from the same registry
  which require different credentials, it would not work with a single
  placeholder secret. Bet: this scenario is rare.
* Package repository bundle would be stored in a similar location as referenced
  package bundles (at least for vmware use cases), hence in practice users would
  only have to add a single registry credential to access package repo bundle
  and package contents bundles.


## How does this integrate with PackageRepository CR?

Explicit configuration: PackageRepository is configured with a secret reference
(name+namespace fields)

Auto configuration: For each fetcher, kapp-controller creates a placeholder
secret in the repository's namespace and uses it when fetching. kapp-controller
must react when secrets change contents (though it may only be useful to do so
when package installation fails due to fetching).

## How does this integrate with PackageInstall CR?

PackageInstall CR does not surface details about how underlying App CR
(generated based on Package CR) is fetching configuration contents which means
that the user does not have an opportunity to configure it.

Explicit configuration: not currently possible (TBD should we expose
configuration override? what if there are multiple fetch directives? support
spec.fetch section that allows to augment fetchers with secretRefs?)

Auto configuration: kapp-controller creates App CR with placeholder secrets for
each fetcher in the App CR namespace. kapp-controller will react when secrets
are populated to redeploy app (assumption is that empty secrets will be tried
but will result in failure; when secrets get populated with contents, fetchers
would succeed).

## How does this integrate with container images (aka Pods)?

Pod configuration may be in various states of configuration:
* Pod uses custom image pull secrets
* Pod uses custom service account
* Pod uses default service account

Specified image pull secrets are considered optional on Pod, so if a named image
pull secret does not exist it will not "block" container creation. However, you
can create a Pod with an image pull secret that does not exist and create the
pull secret a tiny bit later -- Pod seems to start successfully (this is an
important behaviour because even though most of k8s is ever reconciling in
theory, not everything implements it that way). Pods also seem to react
correctly when image is failing to be pulled and pull secret is modified to have
correct auth info (original value could be empty pull secret aka "{}" for
.dockerconfigjson field).

* (verified) Even though service accounts can be modified to add an image pull
  secret, Pods will not adopt the added image pull secret after Pod is created
  (field is immutable). If Pod has explicit imagePullSecrets field specified, SA
  specified ones will not be included. (docs ref)
* (verified) imagePullSecrets field on Pod is immutable.
* (verified) if Pod specifies imagePullSecrets then service account pull secrets
  will not be "added" to the Pod.
* (verified) Kubernetes will try all image pull secrets associated with a Pod
  even if they contain credentials against the same registry. (Note that this
  would not be something supported by this proposal since we are merging
  multiple pull secrets into a single Kubernetes secret and unfortunately a
  single secret cannot have multiple credentials for exactly the same registry).

Based on the above, Pods specifying image pull secret directly is the most
"reliable" way of associating pull information. This could be achieved via
configuration modification or injection via webhooks.

Explicit configuration: Pod configuration should reference an image pull secret.

Auto configuration: Pod configuration should reference an image pull secret
that's a placeholder secret so that it gets populated automatically. (I could
also imagine placeholder secret automatically added via admission webhook to
Pod's image pull secrets field. Mentioned in below "Future enhancements"
section.)

## How does this integrate with App CRs (general case)?

App CR could be compared to Pods in terms of abstraction level. It should
specify a secret ref directly even if it doesn't exist. Unlike Pods, App CR does
consider secret refs required, though I could see adding explicit optional
field.

Explicit configuration: specify secret refs yourself as part of App CR.

Auto configuration: App CR configuration should reference a placeholder secret
so that it gets automatically populated with appropriate credentials.

Example flow:

Note that in this example below only one registry credential was added to the cluster.

* User wants to use package repo containing an operator package
  * (Assuming kapp-controller and secretgen-controllers are installed on the
    cluster)
  * User registering repos:
    * Add Secret "private-reg-creds" that contains credentials
    * Create SecretExport "private-reg-creds" to export secret to all namespaces
    * Create PackageRepository "operator.carvel.dev" with url for repo bundle
    * kapp-controller created placeholder secret for fetching repo bundle is
      populated with "private-reg-creds"
  * User installing a package:
    * Create Namespace "op-install"
    * Create PackageInstall "operator" in that namespace
    * kapp-controller created placeholder secret for fetching pkg bundle is
      populated with "private-reg-creds" If the operator needs to create pods
      with permissions to pull images, it can be modified to create placeholder
      secrets that are referenced by the pods' imagePullSecrets field. These
      will then be populated with the proper creds, allowing the operator pods
      to successfully pull images

# Future Details

## Future Enhancements
Future enhancements (aka more magic) that may make package author lives easier so that they do not need to include placeholder secret in their own configuration:
* we could try adding mutating admission webhook that always adds placeholder image pull secret to all service accounts created so that it get inherited by the Pod
* we could try adding mutating admission webhook that adds placeholder image pull secret directly to Pods (this enhancement may enable more targeted image pull secret selection since image locations would be available in context)

## Open Questions
* ECR authentication to registry uses short lived tokens
  * (separate controller that keeps on updating secret? => might cause a lot of churn in redeploys)
* Effective testing of package configuration with or without registry credentials
  * Do we need this?
* How should secretgen-controller be installed on clusters by TKG and TMC?
