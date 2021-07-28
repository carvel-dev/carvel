## Adding a PackageRepository

kapp-controller needs to know which packages are available to install.
One way to let it know about available packages is by creating a package repository.
To do this, we need a PackageRepository CR:

```
cat > repo.yml << EOF
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: simple-package-repository
spec:
  fetch:
    imgpkgBundle:
      image: ${REPO_HOST}/packages/my-pkg-repo:1.0.0
EOF
```{{execute}}

(See our
[demo video](https://www.youtube.com/watch?v=PmwkicgEKQE) and [website](https://carvel.dev/kapp-controller/docs/latest/package-consumption/#adding-package-repository) examples for more typical
use-case against an external repository.)

This PackageRepository CR will allow kapp-controller to install any of the
packages found within the `${REPO_HOST}/packages/my-pkg-repo:1.0.0` imgpkg bundle, which we
stored in our docker OCI registry previously.

We can use kapp to apply it to the cluster:
`kapp deploy -a repo -f repo.yml -y`{{execute}}

Check for the success of reconciliation to see the repository become available:
`watch kubectl get packagerepository`{{execute}}

Once the simple-package-repository has a "**Reconcile succeeded**" description,
we're ready to continue! You can exit the watch by hitting control-c or
clicking: `^C`{{execute ctrl-seq}}

Once the deploy has finished, we are able to list the package metadatas to see, at a high level, which packages are now available within our namespace:
`kubectl get packagemetadatas`{{execute}}

If there are numerous available packages, each with many versions, this list can become a bit unwieldy, so we can also list the packages with a particular name using the --field-selector option on kubectl get.
`kubectl get packages --field-selector spec.refName=simple-app.corp.com`{{execute}}

From here, if we are interested, we can further inspect each version to discover
information such as release notes, installation steps, licenses, etc. For
example:
`kubectl get package simple-app.corp.com.1.0.0 -o yaml`{{execute}}


