---
title: "Adding CRD Upgrade Safety to kapp"
authors: ["Bryce Palmer <bpalmer@redhat.com>"]
status: "accepted"
approvers: ["Carvel Maintainers"]
---

# Adding CRD Upgrade Safety to kapp

## Problem Statement

CustomResourceDefinitions (CRDs) are an integral part of extending the Kubernetes API and are often applied to a cluster alongside a controller that manages them.

Since CRDs are global and only one instance can exist on the cluster at a time, it is important to ensure that updates to a CRD are performed safely.
This means preventing data loss and breaking of clients/workloads that may be using the API.
Failure to safely update a CRD may result in:

- Existing CustomResources (CRs) being invalidated, causing extensions to fail reconciliation of the existing CRs
- Breaking clients expecting the old schema to be present. This may include other extensions, workloads, and tooling that depend on a specific version of the CRD.

When an unsafe update occurs, it requires manual intervention to update all of the existing CRs to the new version of the CRD.

## Terminology / Concepts

- CustomResourceDefinition (CRD) - https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
- CustomResource (CR) - https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- Fail Closed - In the scope of this document, "failing closed" is used to represent that if we can't explicitly validate something then we should fail.
- Fail Open - In the scope of this document, "failing open" is used to represent that if we can't explicitly validate something then we should succeed.
- Preflight Check - A preflight check is a validation that is run prior to performing some action. Typically, if the validation fails the action will not be performed.

## Proposal

In order to address the problem identified, it is proposed that a new, optional, preflight check is added to `kapp` to enable verifying that an `update` operation on a CRD is safe before attempting to apply any changes to the cluster.

### Goals and Non-goals

#### Goals

- Providing `kapp` users a way to enable verification that an `update` operation on CRDs is safe and won't cause data loss or break clients
- Providing `kapp` users a way to configure preflight checks via the `kapp` configuration file

#### Non-goals

- Anything not pertaining to providing `kapp` users a way to ensure that `update` operations on CRDs are safe before applying changes

### Specification

Building on top of the existing preflight implementation, a new preflight check will be added to `kapp` called `CRDUpgradeSafety`.

For more information on the preflight implementation see:

- [Pull Request adding preflight checks to `kapp`](https://github.com/carvel-dev/kapp/pull/887)
- [Pull Request adding `--preflight` flag to `kapp` documentation](https://github.com/carvel-dev/carvel/pull/726)

#### `CRDUpgradeSafety` Logic

Updates to a CRD can be deemed unsafe if any of the following occur:

- An existing version that is a stored version in the object store is removed
- Scope of a CRD is changed from Namespace to Cluster (or vice versa)
- Removing a field in an existing version
- Adding a new required field
- Updates to an existing field that makes validation more restrictive or would break existing versions/clients. Some brief examples: changing a field's type from string to int, increasing minimum value, removing an enum value.

The most straightforward changes to validate are the first four and will have explicit validations in the implementation.

Validation for breaking changes to an existing field is much more nuanced and is more difficult to catch all valid cases.
It is proposed that an iterative approach is taken where the base implementation does not contain any specific validations against changed fields, but is written in a way that it is easy to add validations in the future.
This does not mean that we shouldn't add any specific validations against changed fields before a release of `kapp` containing this preflight check, but rather focus on laying a foundation in which we can iteratively build on.
Some potential field validations we could add after the base implementation is in place are:

- Type is not changed
- Enum value is not removed
- Minimum value is not increased
- Maximum value is not decreased

Due to the nature of this check, it is anticipated that users will want to be able to configure the behavior to best meet their needs. To start with, there will be a couple configuration options for this preflight check:

- **mode** - allowed values: ["error", "warn"] - This is the mode that should be used when running the preflight check. When run in the `error` mode, this check will fail if any problems are found with upgrading a CRD and prevent the changes from being applied to the cluster. When run in `warn` mode, this check will always succeed, but log warnings for any problems found. The `warn` mode allows users to be aware of potential problems but proceed with applying the changes to the cluster if all other enabled preflight checks pass. `error` is the default.
- **failMode** - allowed values: ["open", "closed"] - This is the failure mode that should be used when running the preflight check. Only used when `mode=error`. When running in the `open` mode, if a change to an existing field is not validated by an existing check the preflight check will pass. When running in the `closed` mode, all changes to an existing field _must_ be validated by an existing check. If it has not, the preflight check will fail with a message along the lines of "unable to determine if change to existing field is safe ...". `closed` is the default.

#### Preflight Configuration

The `CRDUpgradeSafety` preflight check is a very nuanced preflight check and different users will likely want to be able to configure this check a bit further to do things like:

- Only issue warnings about potential problems
- Fail closed/open

In order to accomodate this configurability without introducing various versions of the same preflight check, the ability to specify preflight configurations will be added to the existing [`kapp` configuration file](https://carvel.dev/kapp/docs/v0.60.x/config/).

As an example, configuring a preflight check could look something like:

```yaml
apiVersion: kapp.k14s.io/v1alpha1
kind: Config
...
preflightRules:
  - name: Check
    config:
      paramOne: somevalue
      paramTwo: [1, 2, 3]
  - name: OtherCheck
    config:
      otherParamOne:
        value: foo
...
```

Each entry in the `preflight` field contains the `name` of the preflight check and an optional map of configuration values (specified by the `config` field).
If a preflight check is specified it is enabled, otherwise it is disabled.
Configuring a non-existent preflight check will result in an error.

The existing `--preflight` flag can be used to override the list of enabled/disabled preflight checks in the configuration file.
Any preflight checks not specified in the `--preflight` flag are disabled.

To provide a high quality user experience, each configurable preflight check should have a sane default where possible.

#### Use Cases

##### Upgrading an Operator/Controller with the `CRDUpgradeSafety` Preflight Check Enabled

- Operators/Controllers typically include CRDs in their manifests
- If the new version of an Operator/Controller contains a breaking change in the CRD it is blocked to prevent breaking the cluster

### Other Approaches Considered

#### Multiple Preflight Checks

This approach would focus on adhering to the existing preflight check parameters and not add configuration options to checks. This is undesirable as to achieve the same set of functionality as the proposed approach we would have to introduce at least three new preflight checks similar to:

- `CRDUpgradeSafetyErrorFailOpen`
- `CRDUpgradeSafetyErrorFailClosed`
- `CRDUpgradeSafetyWarn`

All of these preflight checks would do _almost_ the same thing with some small tweaks, but having multiple checks means that a user could enable all 3 of the checks which could lead to unexpected behavior.

#### Do Nothing

Doing nothing will mean that users will not have a native option to validate updates to CRDs when using `kapp`. This does not solve the problem or provide a safety mechanism for users who might be unaware that an update to a CRD can break things on their cluster.

## Open Questions

- Are there any _valid_ changes to a CRD field that we want to ensure are included in an initial release of `kapp` with this preflight check?

## Answered Questions
