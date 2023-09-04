---
aliases: [/kapp-controller/docs/latest/app-examples]
title: Example Usage
---

Below are some example App CRs showing common ways our users have used App CRs. Full App CR spec can be found [here](app-spec.md).

## Gitops with an app
In this example a user wants to keep their app up to date with changes to the source Git repo

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: simple-app
spec:
  serviceAccountName: default
  fetch:
  - git:
      url: https://github.com/k14s/k8s-simple-app-example
      ref: origin/develop
      subPath: config-step-2-template

  template:
  - ytt: {}

  deploy:
  - kapp: {}
```

## Gitops with a Helm chart
In this example a user wants to keep their cluster up to date with the latest version of a Helm chart fetched from a Git repo
```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: nginx-helm
spec:
  fetch:
  - git:
      url: https://github.com/bitnami/charts
      ref: origin/master
      subPath: bitnami/nginx

  template:
  - helmTemplate:
      valuesFrom:
      - secretRef:
          name: nginx-values

  deploy:
  - kapp: {}
```

## Install a Helm chart
In this example a user wants to keep their cluster up to date with the latest version of a Helm chart
```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: concourse-helm
spec:
  fetch:
  - helmChart:
      name: stable/concourse

  template:
  - helmTemplate:
      valuesFrom:
      - secretRef:
          name: concourse-values

   deploy:
  - kapp: {}
```

## Customize a Helm chart by adding an overlay 
In this example a user wants to use `helm template`, but then modify the resulting YAML by adding their own add their own `ytt overlay` 
```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: concourse-helm
spec:
  fetch:
  - git:
      url: https://github.com/bitnami/charts
      ref: origin/master
      subPath: bitnami/nginx

  template:
  - helmTemplate: {}
  - ytt:
      ignoreUnknownComments: true
      inline:
        paths:
          remove-lb.yml: |
            #@ load("@ytt:overlay", "overlay")
            #@overlay/match by=overlay.subset({"kind":"Service","metadata":{"name":"nginx"}})
            ---
            spec:
              type: ClusterIP
              #@overlay/remove
              externalTrafficPolicy:
  
  deploy:
  - kapp: {}
```
