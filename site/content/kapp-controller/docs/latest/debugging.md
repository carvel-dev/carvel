---
title: Debugging kapp-controller
---

This documentation covers troubleshooting failures with kapp-controller, where
to look for detailed error messages for kapp-controller custom resources (CRs),
and where to look when you need more information than what is presented in error
messages.

## Debugging kapp-controller CRs

When encountering errors with kapp-controller, your first alert to a failure
will come from the tool(s) (e.g. kapp or kubectl) you are using to deploy
kapp-controller CRs. `kapp` will more immediately tell you if a resource you are
creating or updating fails, but you will need to verify with a `kubectl get` if
using `kubectl` to create/update.

You can verify a failure occurred by running a `kubectl get` for the resource
you encountered the failure with. You can then see in the `DESCRIPTION` column
of the output of `kubectl get` if the reconciliation process for the resource
failed. An example of this is below:

```
NAMESPACE   NAME                  PACKAGE NAME          PACKAGE VERSION   DESCRIPTION                                                            AGE
foo         instl-pkg-test-fail   pkg.fail.carvel.dev   1.0.0             Reconcile failed: Error (see .status.usefulErrorMessage for details)   12s
```

Once you have confirmed an error occurred, you can review the status of the CR
for more information.  With the exception of Packages and PackageMetadatas, each
CR has a status that will show error messages for failures.

Apps, PackageInstalls, and PackageRepsitories all feature a status property
named `usefulErrorMessage`. `usefulErrorMessage` will contain an error message
from kapp-controller or the stderr from the underlying tool used by
kapp-controller (i.e. vendir, imgpkg, kbld, ytt, kapp, or helm).

`usefulErrorMessage` will be located at the bottom of the statuses if running a
`kubectl get` or `kubectl describe` to view more information about a failure.

`usefulErrorMessage` can also be accessed more directly through `kubectl` like
in the following examples:

```
# App errors
$ kubectl get apps/simple-app -o=jsonpath={.status.usefulErrorMessage} -n namespace

# PackageInstall errors
$ kubectl get packageinstall simple-app -o=jsonpath={.status.usefulErrorMessage} -n namespace

# PackageRepository errors (cluster scoped so no namespace)
$ kubectl get packagerepository repo -o=jsonpath={.status.usefulErrorMessage}
```

### Debugging App CRs

Failures can arise from fetch, template, deploy, or delete steps for an App CR.
These failures correspond to issues with runtime information declared in the App
CR's spec.

Errors are reported as stderr from associated tools used in kapp-controller
(i.e. vendir, imgpkg, kbld, ytt, kapp, and helm) or as direct messages from
kapp-controller (e.g. when an App uses a ServiceAccount that doesn't exist). 

When a failure occurs with an App CR, you can find further details in the App
CR's `DESCRIPTION` column by running `kubectl get apps/simple-app -n namespace`:

```
NAME         DESCRIPTION                                                                                         SINCE-DEPLOY   AGE
simple-app   Delete failed: Preparing kapp: Getting service account: serviceaccounts "default-ns-sa" not found   3s             56m
```

In the case above, the error message shown is coming directly from
kapp-controller, so all the information for the failure should be presented in
the description column. This commonly occurs when references used by
kapp-controller (e.g. secrets, configmaps, serviceaccounts) are not found by
kapp-controller.

In cases where the error message does not originate from kapp-controller (e.g. a
failed fetch event for a git repository), the stderr from the underlying tool
(i.e. vendir, imgpkg, kbld, ytt, kapp, and helm) is shown in the App's status. 

In the App status, there is a field called `usefulErrorMessage` that displays
the stderr for a failure during App reconciliation.

This `usefulErrorMessage` field can be found by running `kubectl get
apps/simple-app -o=jsonpath={.status.usefulErrorMessage} -n namespace`.  The
kubectl command will return the stderr output from the App status to help you
further understand the reason for the App failure.

The `usefulErrorMessage` can be helpful in pointing out where errors occurred
from inputs in the App spec and also pinpoint the resource that caused a
deployment failure. However, Apps will not surface errors of resources they are
deploying to Kubernetes and further debugging of resources deployed by an App
may be needed.

### Debugging PackageInstall CRs

Failures for PackageInstalls can be viewed directly via the `usefulErrorMessage`
property of the PackageInstall's status. This `usefulErrorMessage` property
comes from an App CR that is created as a result of creating a PackageInstall.
More information on interpreting the error message from `usefulErrorMessage` can
be found under the [Debugging App CRs](#debugging-app-crs).  The underlying App
CR will have the same name as the PackageInstall that you create.

In addition to understanding the error from the underlying App CR, it can also
be useful the inspect the Package definition to see if there are issues for the
Package being deployed by the PackageInstall.

You can view the Package details by running the following command:

```
$ kubectl describe package/<package name>
```

You can then view the `.template.spec` of the Package to see if there are any
issues with the inputs of the Package. These inputs are eventually used to
create the App for the PackageInstall and can lead to failures.

### Debugging PackageRepository CRs

The primary responsibility of the PackageRepository is to fetch the
configuration for all of its Packages, which are typically pulled from an OCI
registry as an [imgpkgBundle](/imgpkg/docs/latest/resources/#bundle). Failures
for PackageRepositories most often happen from fetching the PackageRepository
contents (i.e. the `.spec.fetch` portion of the PackageRepository spec).

Failures for PackageRepositories can be viewed directly via the
`usefulErrorMessage` property of the PackageRepository's status.  Interpreting
the error message from `usefulErrorMessage` for PackageRepositories is very
similar to debugging an App CR's status.  More information on interpreting the
errors from App CRs can be found under under the [Debugging App
CRs](#debugging-app-crs) section. 

Common problems encountered with PackageRepositories may be needing
authentication for a registry where an image or imgpkg bundle is stored (read
more [here](package-consumption/#adding-package-repository) on
PackageRepositories authenticating to a private registry) and proper formatting
of Package resources.
