---
aliases: [/kapp-controller/docs/latest/walkthrough]
title: Install an Application
---

This walkthrough demonstrates how to install an example application on Kubernetes with kapp-controller. The example application is an HTTP server. You will use `examples/simple-app-git` directory for the YAML configuration.

You can use [kapp](/kapp) or another tool such as kubectl to deploy the following YAML examples:

1. [Install](install.md) kapp-controller onto your cluster.

1. Install [examples/default-ns-rbac.yml](https://github.com/carvel-dev/kapp-controller/blob/develop/examples/rbac/default-ns.yml).

    It creates `default-ns-sa` service account to change resources within the `default` namespace. The App CR in the next step uses the service account.

    ```bash-plain
    $ kapp deploy -a default-ns-rbac -f https://raw.githubusercontent.com/carvel-dev/kapp-controller/develop/examples/rbac/default-ns.yml
    ```

1. Install [examples/simple-app-git/1.yml](https://github.com/carvel-dev/kapp-controller/blob/develop/examples/simple-app-git/1.yml) App CR.

    It specifies how to fetch, template, and deploy the example application.

    ```bash-plain
    $ kapp deploy -a simple-app -f https://raw.githubusercontent.com/k14s/kapp-controller/develop/examples/simple-app-git/1.yml
    # or... kubectl apply -f https://raw.githubusercontent.com/k14s/kapp-controller/develop/examples/simple-app-git/1.yml

    Changes

    Namespace  Name        Kind  Conds.  Age  Op      Wait to    Rs  Ri
    default    simple-app  App   -       -    create  reconcile  -   -

    Op:      1 create, 0 delete, 0 update, 0 noop, 0 exists
    Wait to: 1 reconcile, 0 delete, 0 noop

    Continue? [yN]: y

    5:20:27PM: ---- applying 1 changes [0/1 done] ----
    5:20:27PM: create app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:20:27PM: ---- waiting on 1 changes [0/1 done] ----
    5:20:27PM: ongoing: reconcile app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:20:33PM: ok: reconcile app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:20:33PM: ---- applying complete [1/1 done] ----
    5:20:33PM: ---- waiting complete [1/1 done] ----

    Succeeded
    ```

1. Run `kubectl get app` to verify that the app is deployed.

1. Verify the status of the App CR.

    **Note:** As of kapp-controller v0.31.0, inspect is deactivated by default. See [App CR spec](app-spec.md) for more details.

    ```bash-plain
    $ kapp inspect -a simple-app --status
    # or... kubectl get app simple-app -oyaml

    Resources in app 'simple-app'

    Namespace  default
    Name       simple-app
    Kind       App
    Status     conditions:
               - status: "True"
                 type: ReconcileSucceeded
               deploy:
                 exitCode: 0
                 finished: true
                 startedAt: "2019-12-02T22:20:28Z"
                 stdout: |-
                   Changes
                   Namespace  Name        Kind        Conds.  Age  Op      Wait to    Rs  Ri
                   default    simple-app  Deployment  -       -    create  reconcile  -   -
                   ^          simple-app  Service     -       -    create  reconcile  -   -
                   Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
                   Wait to: 2 reconcile, 0 delete, 0 noop
                   10:20:28PM: ---- applying 2 changes [0/2 done] ----
                   10:20:28PM: create service/simple-app (v1) namespace: default
                   10:20:28PM: create deployment/simple-app (apps/v1) namespace: default
                   10:20:29PM: ---- waiting on 2 changes [0/2 done] ----
                   10:20:29PM: ok: reconcile service/simple-app (v1) namespace: default
                   10:20:29PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
                   10:20:29PM:  ^ Waiting for 1 unavailable replicas
                   10:20:29PM:  L ok: waiting on replicaset/simple-app-6fb57f844b (apps/v1) namespace: default
                   10:20:29PM:  L ongoing: waiting on pod/simple-app-6fb57f844b-jk7d8 (v1) namespace: default
                   10:20:29PM:     ^ Pending: ContainerCreating
                   10:20:29PM: ---- waiting on 1 changes [1/2 done] ----
                   10:20:31PM: ok: reconcile deployment/simple-app (apps/v1) namespace: default
                   10:20:31PM: ---- applying complete [2/2 done] ----
                   10:20:31PM: ---- waiting complete [2/2 done] ----
                   Succeeded
                 updatedAt: "2019-12-02T22:20:31Z"
               fetch:
                 exitCode: 0
                 startedAt: "2019-12-02T22:20:27Z"
                 updatedAt: "2019-12-02T22:20:27Z"
               inspect:
                 exitCode: 0
                 stdout: |-
                   Resources in app 'simple-app-ctrl'
                   Namespace  Name                              Kind        Owner    Conds.  Rs  Ri  Age
                   default    simple-app                        Deployment  kapp     2/2 t   ok  -   4s
                   default     L simple-app-6fb57f844b          ReplicaSet  cluster  -       ok  -   4s
                   default     L.. simple-app-6fb57f844b-jk7d8  Pod         cluster  4/4 t   ok  -   4s
                   default    simple-app                        Service     kapp     -       ok  -   4s
                   default     L simple-app                     Endpoints   cluster  -       ok  -   4s
                   Rs: Reconcile state
                   Ri: Reconcile information
                   5 resources
                   Succeeded
                 updatedAt: "2019-12-02T22:20:32Z"
               observedGeneration: 2
               template:
                 exitCode: 0
                 updatedAt: "2019-12-02T22:20:28Z"

    1 resources

    Succeeded
    ```

    The output shows the overall status of the application, including the latest deploy output (`status.deploy.stdout`) and the latest inspect output (`status.inspect.stdout`). Based on the inspect output you can see that the app included a `Deployment` and a `Service`.

1. Update `simple-app` App CR to reconfigure it.

    This example changes data values for ytt templates.

    ```bash-plain
    $ kapp deploy -a simple-app -f https://raw.githubusercontent.com/k14s/kapp-controller/develop/examples/simple-app-git/2.yml -c
    # or... kubectl apply -f https://raw.githubusercontent.com/k14s/kapp-controller/develop/examples/simple-app-git/2.yml

    --- update app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
      ...
     23, 23     template:
     24     -   - ytt: {}
         24 +   - ytt:
         25 +       inline:
         26 +         pathsFrom:
         27 +         - secretRef:
         28 +             name: simple-app-values
     25, 29   status:
     26, 30     conditions:
    --- create secret/simple-app-values (v1) namespace: default
          0 + apiVersion: v1
          1 + kind: Secret
          2 + metadata:
          3 +   labels:
          4 +     kapp.k14s.io/app: "1575325198404867000"
          5 +     kapp.k14s.io/association: v1.7a671029ad7db07aa797301eac59e9ad
          6 +   name: simple-app-values
          7 +   namespace: default
          8 + stringData:
          9 +   values2.yml: |
         10 +     #@data/values
         11 +     ---
         12 +     hello_msg: updated
         13 +

    Changes

    Namespace  Name               Kind    Conds.  Age  Op      Wait to    Rs  Ri
    default    simple-app         App     1/1 t   2m   update  reconcile  ok  -
    ^          simple-app-values  Secret  -       -    create  reconcile  -   -

    Op:      1 create, 0 delete, 1 update, 0 noop, 0 exists
    Wait to: 2 reconcile, 0 delete, 0 noop

    Continue? [yN]: y

    5:23:13PM: ---- applying 2 changes [0/2 done] ----
    5:23:13PM: update app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:23:13PM: create secret/simple-app-values (v1) namespace: default
    5:23:14PM: ---- waiting on 2 changes [0/2 done] ----
    5:23:14PM: ongoing: reconcile app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:23:14PM: ok: reconcile secret/simple-app-values (v1) namespace: default
    5:23:14PM: ---- waiting on 1 changes [1/2 done] ----
    5:23:17PM: ok: reconcile app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:23:17PM: ---- applying complete [2/2 done] ----
    5:23:17PM: ---- waiting complete [2/2 done] ----

    Succeeded
    ```

1. Delete the `simple-app` App CR.

    ```bash-plain
    $ kapp delete -a simple-app
    # or... kubectl delete -f https://raw.githubusercontent.com/k14s/kapp-controller/develop/examples/simple-app-git/2.yml

    Changes

    Namespace  Name               Kind    Conds.  Age  Op      Wait to  Rs  Ri
    default    simple-app         App     1/1 t   6m   delete  delete   ok  -
    ^          simple-app-values  Secret  -       3m   delete  delete   ok  -

    Op:      0 create, 2 delete, 0 update, 0 noop, 0 exists
    Wait to: 0 reconcile, 2 delete, 0 noop

    Continue? [yN]: y

    5:26:25PM: ---- applying 2 changes [0/2 done] ----
    5:26:25PM: delete secret/simple-app-values (v1) namespace: default
    5:26:25PM: delete app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:26:26PM: ---- waiting on 2 changes [0/2 done] ----
    5:26:26PM: ok: delete secret/simple-app-values (v1) namespace: default
    5:26:26PM: ongoing: delete app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:26:26PM: ---- waiting on 1 changes [1/2 done] ----
    5:26:30PM: ok: delete app/simple-app (kappctrl.k14s.io/v1alpha1) namespace: default
    5:26:30PM: ---- applying complete [2/2 done] ----
    5:26:30PM: ---- waiting complete [2/2 done] ----

    Succeeded
    ```
