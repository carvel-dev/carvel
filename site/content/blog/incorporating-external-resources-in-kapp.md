---
title: "Incorporating external resources in kapp"
slug: incorporating-external-resources-in-kapp
date: 2021-12-24
author: Praveen Rewar
excerpt: "How to use kapp's exists annotation to wait for resources created by external agencies"
image: /img/logo.svg
tags: ['Praveen', 'kapp', 'exists']
---

kapp CLI encourages Kubernetes users to manage resources in bulk by working with "Kubernetes applications" (sets of resources with the same label). But their are often times when we want to incorporate resources that are not actually part of the same application (created by external agents). 

In this blog, we are going to learn how to use the `kapp.k14s.io/exists` annotation to wait for resources that are not owned by kapp and are not labeled.

## Problem Statement
Let's take a look at an example application which consists of a _configmap_ and a _secret_ both of which needs to be created in a namespace which is not part of the application and it will be created by an external agency (such as a controller).

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-sample
  namespace: ns-sample
data:
  player_initial_lives: "3"
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-sample
  namespace: ns-sample
data:
  extra: YmFyCg==
```

If we try to deploy this application, we would get an error suggesting that the namespace _ns-sample_ doesn't exists.

{{< detail-tag "Bash" >}}
```bash
kapp deploy -a test -f config.yml
Target cluster 'https://192.168.64.53:8443' (nodes: minikube)

Changes

Namespace  Name              Kind       Conds.  Age  Op      Op st.  Wait to    Rs  Ri
ns-sample  configmap-sample  ConfigMap  -       -    create  -       reconcile  -   -
^          secret-sample     Secret     -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop
Wait to: 2 reconcile, 0 delete, 0 noop

Continue? [yN]: y

9:24:14AM: ---- applying 2 changes [0/2 done] ----
9:24:14AM: create secret/secret-sample (v1) namespace: ns-sample

kapp: Error: Applying create secret/secret-sample (v1) namespace: ns-sample:
  Creating resource secret/secret-sample (v1) namespace: ns-sample: namespaces "ns-sample" not found (reason: NotFound)
```
{{< /detail-tag >}}

We know that the namespace will be created by a controller at some point of time, but how do we make sure that we are creating our resources after the namespace has been created. Should we wait for the creation of the namespace and then deploy our app? Sounds mundane, right? Well, we do have a solution for this which will allow us to deploy the app and let kapp do the waiting on it's own. We will use the `kapp.k14s.io/exists` annotation for this.

## How to use the _exists_ annotation
To use the _exists_ annotation, we would need the basic information of the resource that we want to wait for. By basic, we mean the information that uniquely identifies the resource. For example, we would need the _apiVersion_, _kind_ and _name_ of a namespace to wait for it.
Next step is to add this information in the yaml along with the other resources and add the exists annotation to it. So, our yaml would now look something like this.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ns-sample
  annotations:
    kapp.k14s.io/exists: ""
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-sample
  namespace: ns-sample
data:
  player_initial_lives: "3"
---
apiVersion: v1
kind: Secret
metadata:
  name: secret-sample
  namespace: ns-sample
data:
  extra: YmFyCg==
```

If we deploy the application now, we will notice that kapp would start waiting for the namespace to be created. Meanwhile we can open another tab in our terminal and create the namespace, and we would notice that kapp would then proceed on to creating the configmap and the secret.

```bash
kapp deploy -a test -f config.yml
Target cluster 'https://192.168.64.53:8443' (nodes: minikube)

Changes

Namespace  Name              Kind       Conds.  Age  Op      Op st.  Wait to    Rs  Ri
(cluster)  ns-sample         Namespace  -       -    exists  -       reconcile  -   -
ns-sample  configmap-sample  ConfigMap  -       -    create  -       reconcile  -   -
^          secret-sample     Secret     -       -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop, 1 exists
Wait to: 3 reconcile, 0 delete, 0 noop

Continue? [yN]: y

10:11:24AM: ---- applying 1 changes [0/3 done] ----
10:11:24AM: exists namespace/ns-sample (v1) cluster
10:11:24AM:  ^ Retryable error: External resource doesnt exists
10:11:37AM: exists namespace/ns-sample (v1) cluster
10:11:37AM: ---- waiting on 1 changes [0/3 done] ----
10:11:37AM: ok: reconcile namespace/ns-sample (v1) cluster
10:11:37AM: ---- applying 2 changes [1/3 done] ----
10:11:37AM: create secret/secret-sample (v1) namespace: ns-sample
10:11:37AM: create configmap/configmap-sample (v1) namespace: ns-sample
10:11:37AM: ---- waiting on 2 changes [1/3 done] ----
10:11:37AM: ok: reconcile configmap/configmap-sample (v1) namespace: ns-sample
10:11:37AM: ok: reconcile secret/secret-sample (v1) namespace: ns-sample
10:11:37AM: ---- applying complete [3/3 done] ----
10:11:37AM: ---- waiting complete [3/3 done] ----

Succeeded
```

## Real World Example: Gatekeeper

We usually come across scenarios where a controller creates a CRD and we would be deploying a CR of that kind. One such example is the creation of [Constraints](https://open-policy-agent.github.io/gatekeeper/website/docs/howto#constraints) in [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/).

To create a Constraint, we are first required to create a [ConstraintTemplate](https://open-policy-agent.github.io/gatekeeper/website/docs/howto#constraint-templates), which triggers the creation of a CRD by the gatekeeper controller. Once the CRD is created we then create a CR of that kind which acts a Constraint. Notice that we cannot create the CR until the controller has created the CRD, hence we need to wait for the CRD creation to be completed. Let's try to use the _exists_ annotation here so that we can use kapp to do the waiting for us.
We would need to add the details of the CRD to our deployment and we can get those details from the ConstraintTemplate CR itself. Heres a CRD declaration that you would need to wait for the actual CRD to be created. 

```yaml
apiVersion: apiextensions.k8s.io/v1          #Same for all CRDs
kind: CustomResourceDefinition               #Same for all CRDs 
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: k8srequiredlabels.constraints.gatekeeper.sh    #plural = spec.names.kind (in lowercase)
  annotations:
    kapp.k14s.io/exists: ""
spec:
  group: constraints.gatekeeper.sh           #Same for all Constraint CRDs
  versions:
    - name: v1beta1                          #Same as version of ConstraintTemplate CR
  names:
    kind: K8sRequiredLabels           #This is provided in the ConstraintTemplate CR
```

Now you can deploy gatekeeper along with the Constraint CRs without having to wait for the CRDs manually. Note that you would need to add a few change rules so that the Constraints are deployed after the gatekeeper controller pods are in ready state. Refer to this [gist](https://gist.github.com/praveenrewar/a97820ecef7a79ef13b2f7125421c723) for reference.


## Join us on Slack and GitHub

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
