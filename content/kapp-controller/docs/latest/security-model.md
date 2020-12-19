---
title: Security Model
---

## App CR privileges

kapp-controller container runs with a service account (named `kapp-controller-sa` inside `kapp-controller` namespace) that has access to all service accounts and secrets in the cluster. This service account *is not* used for deployment of app resources.

Each App CR *must* specify either a

- service account (via `spec.serviceAccountName`)
- or, Secret with kubeconfig contents for some cluster (via `spec.cluster.kubeconfigSecretRef.name`)

forcing App CR owner to explicitly provide needed privileges for management of app resources. This avoids a problem of privilege escalation commonly found in other general resource controllers which rely on a shared service account (often requiring cluster admin privileges) to deploy resources.

Since App CR only allows to reference service account or kubeconfig Secret within the same namespace where App CR is located, kapp-controller is well suited for multi-tenant use where different users of App CRD have varied level of access (e.g. some may have cluster level privileges, and other may only have access to one or more namespace).

Example:

- User A has been granted access to namespace `a` (and no other namespace or cluster level access). User A can create an App CR with a service account located in namespace `a` to deploy resources into namespace `a`. It _is not_ possible for user A to create an App CR that would install cluster-wide resources or place resources into another namespace. (e.g. a user that just deploys web application to their namespace)

- User B has been granted access to namespace `b` and ability to manage specifically named CRD (single scoped cluster-wide privilege). User B can create an App CR with a service account located in namespace `b` that installs app into namespace `b` and also manages single CRD lifecycle. (e.g. a user that manages another controller for other users)
