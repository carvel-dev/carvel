## Installing a Package

Once we have the packages available for installation (as seen via `kubectl get packages`{{execute}}), 
we need to let kapp-controller know which package we want to install.
To do this, we will need to create a PackageInstall CR (and a secret to hold the values used by our package):

```bash
cat > pkginstall.yml << EOF
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: pkg-demo
spec:
  serviceAccountName: default-ns-sa
  packageRef:
    refName: simple-app.corp.com
    versionSelection:
      constraints: 1.0.0
  values:
  - secretRef:
      name: pkg-demo-values
---
apiVersion: v1
kind: Secret
metadata:
  name: pkg-demo-values
stringData:
  values.yml: |
    ---
    hello_msg: "to all my katacoda friends"
EOF
```{{execute}}


This CR references the Package we created in the previous sections using the package’s `refName` and `version` fields (see yaml from step 7).
Do note, the `versionSelection` property has a constraints subproperty to give more control over which versions are chosen for installation.
More information on PackageInstall versioning can be found [here](https://carvel.dev/kapp-controller/docs/latest/packaging/#versioning-packageinstalls).

This yaml snippet also contains a Kubernetes secret, which is referenced by the PackageInstall. This secret is used to provide customized values to the package installation’s templating steps. Consumers can discover more details on the configurable properties of a package by inspecting the Package CR’s valuesSchema.

Finally, to install the above package, we will also need to create `default-ns-sa` service account (refer to [Security model](https://carvel.dev/kapp-controller/docs/latest/security-model/)
for explanation of how service accounts are used) that give kapp-controller privileges to create resources in the default namespace:
```bash
kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/examples/rbac/default-ns.yml -y
```{{execute}}

Apply the PackageInstall using kapp:
```bash
kapp deploy -a pkg-demo -f pkginstall.yml -y
```{{execute}}

After the deploy has finished, kapp-controller will have installed the package in the cluster. We can verify this by checking the pods to see that we have a workload pod running. The output should show a single running pod which is part of simple-app:
```bash
kubectl get pods
```{{execute}}

Once the pod is ready, you can use kubectl’s port forwarding to verify the customized hello message has been used in the workload:
```bash
kubectl port-forward service/simple-app 3000:80 &
```{{execute}}

Now if we make a request against our service, we can see that our `hello_msg`
values is being used:
```bash
curl localhost:3000
```{{execute}}
