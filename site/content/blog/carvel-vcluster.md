---
title: "Provisioning and using vclusters with Carvel"
slug: carvel-vcluster
date: 2022-02-08
author: Daniel Helfand
excerpt: "Provision Kubernetes clusters within Kubernetes namespaces using vcluster and Carvel"
image: /img/logo.svg
tags: ['vcluster', 'kapp', 'ytt', 'helm', 'kapp-controller']
---

Your head should hurt a little bit after reading this blog, but hopefully it's because of all 
the ideas you are thinking about around Carvel and [`vcluster`](https://www.vcluster.com/) and 
not because you are unsure what Kubernetes cluster you are using.

`vcluster` is a project from Loft Labs that delivers on an exciting idea: delivering the experience 
of using an independent Kubernetes cluster within a host Kubernetes cluster's namespace. To summarize, 
your cluster can host other clusters.

The idea of vcluster is detailed in [greater detail on the vcluster webiste](https://www.vcluster.com/docs/architecture/basics), 
but a summary from these docs is as follows for what vclusters are:

> the basic idea is that vclusters run as a single pod (scheduled by a StatefulSet) that consists of 2 containers:
> * Control Plane: This container contains API server, controller manager and a connection (or mount) of the data store.
> * Syncer: What makes a vcluster virtual is the fact that it does not have a scheduler. Instead, it uses a so-called syncer 
>   which copies the pods that need to be scheduled from the vcluster to the underlying host cluster.

vclusters are also a [certified Kubernetes distribution](https://github.com/cncf/landscape/pull/2187), so the experience of using these clusters is pretty indistinguishable from other clusters.

Hopefully the introduction to vclusters above is exciting to you. As users of Carvel tools though, you may want 
to understand how the experience of `kapp` looks when using vclusters.

Let's walk through an example of using `kapp` to deploy and also work with vclusters. I am using vcluster version `0.5.3`.

To start, you'll need a Kubernetes cluster. I am using `minikube` in this example. You will also need `helm`, `ytt`, and 
`kapp` to fully go through this walkthrough.

vclusters are packaged as a helm chart. The vcluster CLI actually uses helm quite a bit for management of vclusters. No 
worries though on whether this plays nice with Carvel tools as we can use helm with ytt and kapp pretty smoothly.

To start, we'll need to craft a simple overlay to add an annotation to the vcluster StatefulSet. Since this StatefulSet 
creates a PersistentVolumeClaim, we want to give `kapp` permission to delete it when we are done with our vcluster. 

Go ahead sand save the overlay below to a file named `vcluster-statefulset-overlay.yml`:

```
#! vcluster-statefulset-overlay.yml
#@ load("@ytt:overlay", "overlay")
#@overlay/match by=overlay.subset({"kind":"StatefulSet", "metadata":{"name":"my-vcluster"}}), expects=1
---
spec:
  volumeClaimTemplates:
    #@overlay/match by=overlay.index(0)
    - metadata:
        name: data
        #@overlay/match missing_ok=True
        annotations:
          kapp.k14s.io/owned-for-deletion: ""
```

Next, let's see what `kapp` creates when a vcluster is created:

```
$ helm template my-vcluster vcluster --repo https://charts.loft.sh --set serviceCIDR=10.96.0.0/12 -n host-namespace-1 | ytt -f- -f vcluster-stateful-set-verlay.yml | kapp deploy -a vcluster -f- -c

Namespace         Name                  Kind            Conds.  Age  Op      Op st.  Wait to    Rs  Ri
host-namespace-1  my-vcluster           Role            -       -    create  -       reconcile  -   -
^                 my-vcluster           RoleBinding     -       -    create  -       reconcile  -   -
^                 my-vcluster           Service         -       -    create  -       reconcile  -   -
^                 my-vcluster           StatefulSet     -       -    create  -       reconcile  -   -
^                 my-vcluster-headless  Service         -       -    create  -       reconcile  -   -
^                 vc-my-vcluster        ServiceAccount  -       -    create  -       reconcile  -   -
```

The resources above are what a vcluster consists of. You can also check out all the details of the configuration output 
by kapp for greater detail.

Let's now go ahead and deploy this vcluster to the host cluster you are working with by creating a namespace and running 
the helm, ytt, and kapp commands below:

```
$ kubectl create ns host-namespace-1
$
$ helm template my-vcluster vcluster --repo https://charts.loft.sh --set serviceCIDR=10.96.0.0/12 -n host-namespace-1 | ytt -f- -f vcluster-stateful-set-verlay.yml | kapp deploy -a vcluster -f- -y
```

With your vcluster now deployed to the cluster, you can now access the cluster by doing the following:

1. Grab the kubeconfig to access the vcluster as follows:

`$ kubectl get secret vc-my-vcluster -n host-namespace-1 --template={{.data.config}} | base64 -D > kubeconfig-vcluster.yml`

2. Start a port forward on the pod running vcluster:

`$ kubectl port-forward my-vcluster-0 -n host-namespace-1 8443`

Now go ahead and run a `kubectl get ns` on your host cluster. You will see the following output: 

```
NAME               STATUS   AGE
default            Active   92m
host-namespace-1   Active   90m
kube-node-lease    Active   92m
kube-public        Active   92m
kube-system        Active   92m
```

Next, let's use the virtual cluster kubeconfig and run the same `kubectl get ns command`:

```
$ kubectl get ns --kubeconfig=$(pwd)/kubeconfig-vcluster.yml

NAME              STATUS   AGE
default           Active   14m
kube-system       Active   14m
kube-public       Active   14m
kube-node-lease   Active   14m
```

You will notice there is no `host-namespace-1` namespace and the namespace AGEs are different than the host cluster.

Let's do something a little more interesting now and deploy the famous [Carvel sample app](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes) to the vcluster: 

```
$ kapp deploy -a simple-app -f https://raw.githubusercontent.com/vmware-tanzu/carvel-simple-app-on-kubernetes/develop/config-step-1-minimal/config.yml --kubeconfig=$(pwd)/kubeconfig-vcluster.yml
```

Type in `y` to confirm you would like to deploy the Carvel sample app to the vcluster. 

Once the deployment is successful, let's do another sanity check and see what apps exist on the host cluster:

```
$ kapp ls 

Target cluster 'https://127.0.0.1:49955' (nodes: minikube)

Apps in namespace 'default'

Name      Namespaces        Lcs   Lca
vcluster  host-namespace-1  true  21m

Lcs: Last Change Successful
Lca: Last Change Age

1 apps

Succeeded
```

Looks like it's just the vcluster we deployed. Let's now check and see if simple-app is the app kapp knows 
about on the vcluster:

```
$ kapp ls --kubeconfig=$(pwd)/kubeconfig-vcluster.yml

Target cluster 'https://localhost:8443' (nodes: minikube)

Apps in namespace 'default'

Name        Namespaces  Lcs   Lca
simple-app  default     true  3m

Lcs: Last Change Successful
Lca: Last Change Age

1 apps

Succeeded
```

You should be able to do all the usual things with the simple app, such as starting up a port forward: 

```
$ kubectl port-forward svc/simple-app 8080:80 --kubeconfig=$(pwd)/kubeconfig-vcluster.yml
```

You will get the same friendly `Hello stranger!` response at `localhost:8080`. 

You can try and break this too and see if doing a kapp deploy to the host cluster breaks anything. It 
wont! Both kapp apps named `simple-app` can exist.

When you are finished, you can clean up the vcluster using a kapp delete:

```
$ kapp delete -a vcluster
```

I hope this explains the basics of vcluster and using Carvel tools with vcluster. There are definitely 
still some challenges around using the vcluster CLI if you deploy vclusters using kapp or any non helm tool 
(e.g. listing available vclusters, deleting vcluster, connecting to vclusters), but using Carvel with vclusters 
provisioned in any way should still offer many exciting opportunities for Kubernetes developers.

One of the really interesting opportunities that I have not tried out yet is being able to provision vclusters 
as [kapp-controller Packages](https://carvel.dev/kapp-controller/docs/latest/packaging/#package). This would 
allow users a declaritive workflow for setting up these lightweight dev environments on a host cluster. I am 
hoping to do a follow up later on and share my findings.
