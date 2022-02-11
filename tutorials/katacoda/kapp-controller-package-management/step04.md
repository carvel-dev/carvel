## I believe I was promised kapp-controller?

Use kapp to install kapp-controller (reconciliation may take a moment, which you
could use to read about [kubernetes controller reconciliation loops](https://kubernetes.io/docs/concepts/architecture/controller/)):

```bash
kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml -y
```{{execute}}

Gaze upon the splendor! 

```bash
kubectl get all -n kapp-controller
```{{execute}}

The kapp deployment is managing a replicaset which owns a service and a pod. The
pod is running kapp-controller, which is a kubernetes controller
running its own reconciliation loop.

kapp-controller introduces new Custom Resource (CR) types we'll use throughout this
tutorial, including PackageRepositories and PackageInstalls.

```bash
kubectl api-resources --api-group packaging.carvel.dev
```{{execute}}

You can see other kapp-controller CRs in other groups:

```bash
kubectl api-resources --api-group data.packaging.carvel.dev
```{{execute}}

```bash
kubectl api-resources --api-group kappctrl.k14s.io
```{{execute}}
