---
aliases: [/kapp/docs/latest/apply-waiting]
title: Apply Waiting
---

## Overview

kapp includes builtin rules on how to wait for the following resource types:

- any resource with `metadata.deletionTimestamp`: wait for resource to be fully removed
- any resource matching Config's waitRules: [see "Custom waiting behaviour" below](#custom-waiting-behaviour)
- [`apiextensions.k8s.io/<any>/CustomResourceDefinition`](https://github.com/carvel-dev/kapp/blob/develop/pkg/kapp/resourcesmisc/api_extensions_vx_crd.go): wait for Established and NamesAccepted conditions to be `True` (note that this is wait rule for CustomResourceDefinition resource itself, not CRs)
- `apps/v1/DaemonSet`: wait for `status.numberUnavailable` to be 0
- `apps/v1/Deployment`: [see "apps/v1/Deployment resource" below](#apps-v1-deployment-resource)
- `apps/v1/ReplicaSet`: wait for `status.replicas == status.availableReplicas`
- `batch/v1/Job`: wait for `Complete` or `Failed` conditions to appear
- `batch/<any>/CronJob`: immediately considered done
- `/v1/Pod`: looks at `status.phase`
- `/v1/Service`: wait for `spec.clusterIP` and/or `status.loadBalancer.ingress` to become set
- `apps/v1/StatefulSet`: [see "apps/v1/StatefulSet resource" below](#appsv1statefulset-resource)

If resource is not affected by the above rules, its waiting behaviour depends on aggregate of waiting states of its associated resources (associated resources are resources that share same `kapp.k14s.io/association` label value).

## Controlling waiting via resource annotations

- `kapp.k14s.io/disable-wait` annotation controls whether waiting will happen at all. Possible values: "".
- `kapp.k14s.io/disable-associated-resources-wait` annotation controls whether associated resources impact resource's waiting state. Possible values: "".

## apps/v1/Deployment resource

kapp by default waits for `apps/v1/Deployment` resource to have `status.unavailableReplicas` equal to zero. Additionally waiting behaviour can be controlled via following annotations:

- `kapp.k14s.io/apps-v1-deployment-wait-minimum-replicas-available` annotation controls how many new available replicas are enough to consider waiting successful. Example values: `"10"`, `"5%"`.

## apps/v1/StatefulSet resource

Available in v0.32.0+.

kapp will wait for any pods created from the updated template to be ready based on StatefulSet's status. This behaviour depends on the [update strategy](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies) used.

Note: kapp does not do anything special when `OnDelete` strategy is used. It will wait for StatefulSet to report it's reconciled (expecting some actor in the system to delete Pods per `OnDelete` requirements).

## Custom waiting behaviour

Available in v0.29.0+.

kapp can be extended with custom waiting behaviour by specifying [wait rules as additional config](config.md#wait-rules). (If this functionality is not enough to wait for resources in your use case, please reach out on Slack to discuss further.)
