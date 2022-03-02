---
title: "Migrate existing resources to a new kapp app"
slug: migrate-existing-resources-to-a-new-kapp-app
date: 2022-03-03
author: Praveen Rewar
excerpt: "Migrate from kubectl apply to kapp or move resources across apps"
image: /img/logo.svg
tags: ['carvel', 'kapp']

---

[kapp CLI](/kapp) encourages Kubernetes users to manage resources in bulk by working with "Kubernetes applications" (a set of resources with the same label). But how do we manage resources already present on the cluster (created by kubectl apply or are part of another kapp app)? 

In this blog, we learn how to migrate from `kubectl apply` to a kapp app and move existing resources across kapp apps.

## Migrating from `kubectl apply` to kapp
Switching from kubectl apply to kapp deploy will allow kapp to adopt resources mentioned in a given config. However, kapp will try to insert few of its labels in bodies of some resources, like Deployments and DaemonSets, which may fail due to those resources having immutable fields that kapp tries to update (`spec.selector` on Deployments).

For example, let's consider that we created [this deployment](https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/controllers/nginx-deployment.yaml) using kubectl apply, and now we want to deploy the same using kapp, we would then get the following error:

```bash
kapp: Error: Applying update deployment/nginx-deployment (apps/v1) namespace: default:
  Updating resource deployment/nginx-deployment (apps/v1) namespace: default:
    API server says:
      Deployment.apps "nginx-deployment" is invalid: spec.selector:
        Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app":"nginx", "kapp.k14s.io/app":"1646214670391021000"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable (reason: Invalid)
```

### Option 1
To prevent this failure, add the [`kapp.k14s.io/disable-default-label-scoping-rules: ""`](/kapp/docs/latest/config/#labelscopingrules) annotation to individual resources to prevent kapp from touching the immutable fields when adopting them. Adding the annotation will exclude the resources from label scoping (used to scope resources within the current application). 

The example deployment would then look something like this:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
  annotations:
    kapp.k14s.io/disable-default-label-scoping-rules: ""
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

The annotation doesn't affect the app's ability to track such resources, the only consequence of disabling label scoping is that other resources in other apps cannot have the same label selector. For example, with the above change in place, any other app cannot have a deployment with the same label selector, i.e. `app: nginx`.

### Option 2
Another way to overcome this issue is to use `fallback-on-replace` as an [update strategy](/kapp/docs/latest/apply/#kappk14sioupdate-strategy), which will ask kapp to delete+create the resource on encountering an error while updating it. The update strategy can be used via adding the annotation `"kapp.k14s.io/update-strategy": "fallback-on-replace"`.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
  annotations:
    kapp.k14s.io/update-strategy: "fallback-on-replace"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

The consequence of using this update-strategy is having downtime as the deployment will be deleted and re-created.

## Moving resources across kapp apps

When we try to create an app with resources that are already part of another app, kapp will through an ownership error that says that the resource is already part of another app.
```bash
kapp: Error: Ownership errors:
- Resource 'deployment/nginx-deployment (apps/v1) namespace: default' is already associated with a different app 'foo' namespace: default (label 'kapp.k14s.io/app=1646214636675344000')
```

To overcome this, we can use the flag `--dangerous-override-ownership-of-existing-resources` to override the ownership label on those resources. This would remove these resources from the other app and make them part of the current app.

For some resources like Deployment, if label scoping was turned on (default=yes), then its `spec.selector` would also include app label, which would have to be rewritten by kapp when ownership changes. This will cause an immutable field error during update change since k8s deployment does not support changing selector labels.

Even if we disable the label scoping for these resources, kapp would still try to remove the existing label selector and the deployment would still fail as removing the label selector still means that an update to the field is required.

The only option, in this case, is to use the `fallback-on-replace` update-strategy as mentioned above.

## Join us on Slack and GitHub

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings, happening every Thursday at 10:30am PT / 1:30pm ET. Check out the [Community page](/community/) for full details on how to attend.
