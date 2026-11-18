---
title: "Enhancing Resource Health Monitoring within App CR"
authors: [ "Varsha Prasad Narsing <vnarsing@redhat.com>" ]
status: "in review"
approvers: [ "Carvel Maintainers" ]
---

# Enhancing Resource Health Monitoring within App CR

## Problem Statement

After applying the package contents fetched from the source to the cluster through the App CR, it becomes challenging to ascertain the real-time health status of individual resources within the cluster. This lack of visibility poses a significant challenge for SRE/ops teams tasked with overseeing hundreds or even thousands of clusters. Consequently, having this information integrated into the Kapp controller can establish a centralized and reliable source of truth for monitoring purposes.

## Terminology / Concepts

## Proposal

We intend to extend the existing App API by adding a new status condition to expose the system's health. To do so, the following needs to be implemented:

1. The controller reconciling the App CR needs to dynamically set up watches for the resources being deployed by the package. 
2. Introduce a `Healthy` condition in App CR's `status` [field][app_cr_status].

This field would be set to:
1. `True`: if all the installed resources are healthy.
2. `False`: if there is any error during the `fetch`, `install`, `deploy` step or if any of the resources are unhelathy.

The proposed set to criteria to determine if a resource is healthy or not is described below:

1. A Pod resource will be healthy if/when: 
- `.status.Phase` is Running or Completed.
- If `.status.Phase` is Running, "Available" status condition is True.

2. A ReplicationController resource will be healthy if/when:
- `.spec.replicas` matches `.status.availableReplicas`
- `ReplicaFailure` type condition is not present in the status.

3. A ReplicaSet resource will be healthy if/when:
- `.spec.replicas` matches `.status.availableReplicas`.
- `ReplicaFailure` type condition is not present in the status.

3. A Deployment resource will be healthy if/when:
- `.spec.replicas` matches `.status.availableReplicas`.
- `Available` type condition is true.

4. A StatefulSet resource will be healthy if/when:
- `.spec.replicas` matches `.status.availableReplicas`.
- A DaemonSet resource will be healthy if/when:
`.status.desiredNumberScheduled` matches `.status.numberAvailable`

5. An APIService resource will be healthy if/when: 
- `Available` type condition in status is true.

6. A CustomResourceDefinition resource will be healthy if/when:
- `StoredVersions` has the expected API version for the CRD.

7. All other unspecified resources will be considered healthy.

If any of the watched resource is unhealthy, the `Message` field of the healthy condition will have the statuses of the unhealthy resources ordered lexicographically. 

Since the resources deployed by the App reconciler have informers created for them, any change in the resource state will trigger a reconcile that in turn will re-evaluate the health of all resources. 

#### Use Case: Monitoring the state of resources

Kapp currently has the `inspect` command which lists the resources deployed and their current statuses. The output of the command is also printed out as a part of App's status if enabled through `rawOptions` while creating the CR. 

Though this command provides information about the resources created by the respective App CR, it does so by sending API requests during the reconciliation. Instead, using informers provides additional advantages of having real-time updates, efficient resource utilization and reduced load on API server.

### Other Approaches:

## Open Questions:

1. Can using informers to watch resources increase cache size, potentially impacting the performance?
2. Can the output in the `inspect` status field be combined with that of proposed `healthy` condition?


[app_cr_status]: https://pkg.go.dev/github.com/vmware-tanzu/carvel-kapp-controller/pkg/apis/kappctrl/v1alpha1#AppStatus