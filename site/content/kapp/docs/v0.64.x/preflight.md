---
aliases: [/kapp/docs/latest/preflight]
title: Preflight Checks
---

## Overview

Once the change set is calculated (see [Diff](diff.md) section for details), kapp will run any of the optional preflight checks that have been enabled.

If all enabled preflight checks are successful, kapp will continue to apply the changes in the change set (see [Apply](apply.md) section for further details).

Preflight checks are enabled using the new `--preflight` flag when running `kapp deploy...` or `kapp app-group deploy...`. The `--preflight` flag follows the pattern `--preflight=CheckName,OtherCheck,...` to enable the specified preflight checks. Preflight checks not specified are disabled.

Currently available preflight checks are:
- `PermissionValidation` - *disabled by default* - Validates that a user has the permissions necessary to apply the changes in the change set. If a user does not have the appropriate permissions the preflight check will fail and no changes will be applied to the cluster.

## PermissionValidation

The `PermissionValidation` preflight check validates that a user has the permissions necessary to apply the changes in the change set to the cluster. If a user does not have the appropriate permissions to apply *all* of the changes, this check will fail and result in no changes being applied to the cluster.

This preflight check is disabled by default but can be enabled with `--preflight=PermissionValidation` when running `kapp deploy...` or `kapp app-group deploy...`.

The following permission checks are run when this check is enabled:
- For all resources, verification that a user has the permissions to perform the change operation (`create`, `update`, `delete`).
- For `ClusterRole`, `ClusterRoleBinding`, `Role`, and `RoleBinding` resources, verification that no privilege escalation occurs. This is done by checking each rule specified in the `(Cluster)Role` resource (or in the case of `(Cluster)RoleBinding` the referenced `(Cluster)Role`) and ensuring that a user has the same level of permissions. This check also accounts for users with the `escalate` and `bind` permissions that are allowed to perform privilege escalation.
