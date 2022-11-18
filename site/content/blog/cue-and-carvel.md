---
title: "Using CUE and Carvel Together for Your Kubernetes Setup"
slug: cue-and-carvel
date: 2022-11-09
author: Dmitriy Kalinin
excerpt: "In this blog, we share examples of how to use CUE and kapp-controller together as part of your GitOps workflow."
image: /img/logo.svg
tags: ['cue', 'kapp', 'impgkg', 'kapp-controller', 'gitops', 'vendir']
---

[CUE](https://cuelang.org/) is a relatively young (but promising) programming language that enables working with data -- building data structures, validating them, querying and extracting parts. More recently you might have run into CUE being used within several tools, such as Dagger (we've written about [kapp and Dagger](/blog/kapp-and-dagger/) some time ago).

In this post, we'll dig into a few CUE examples for Kubernetes and see how we can use CUE and Carvel tools together. And perhaps at the end of this post, you might be interested in using CUE and Carvel as part of your Kubernetes setup.

### Using CUE to build Kubernetes configuration

Let's start with a simple CUE example that includes Kubernetes Deployment and Service resources:

`app.cue`:
```
package app

deployment: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        namespace: "default"
        name:      "simple-app"
    }
    spec: {
        selector: matchLabels: "simple-app": ""
        template: {
            metadata: labels: "simple-app": ""
            spec: containers: [{
                name:  "simple-app"
                image: "docker.io/dkalinin/k8s-simple-app"
                env: [{
                    name:  "HELLO_MSG"
                    value: "stranger"
                }]
            }]
        }
    }
}

service: {
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        namespace: "default"
        name:      "simple-app"
    }
    spec: {
        ports: [{
            port:       80
            targetPort: 80
        }]
        selector: "simple-app": ""
    }
}
```

There are several things to note:
- Curly braces are explicitly used to contain maps (key-value structures)
- Brackets are explicitly used to specify collections
- Strings are always quoted, which is unlike YAML where it's optional until you find ambiguity with other types, like integers.
- There is no notion of "documents" like in YAML -- root element of a file (and a package) is a map, hence if you want to include multiple Kubernetes resources, you'll have to find a "non-document" way to make them coexist (we'll dig into this next). CUE provides a handy `cue import` command that may be helpful to do conversion in bulk so check out examples in its help message or in [this tutorial](https://github.com/cue-lang/cue/blob/v0.4.3/doc/tutorial/kubernetes/README.md#importing-existing-configuration).
- There is a single-line shorthand syntax to specify nested maps (see Deployment's `spec.selector` line)

By the way, as you go along these examples feel free to use interactive [CUE playground](https://cuelang.org/play/#cue@export@cue) or [install CUE binary](https://github.com/cue-lang/cue#download-and-install) to run them locally. Also you may find it useful to refer to [CUE documentation](https://cuelang.org/docs/) as you read along for more in-depth explanation on specifics.

To evaluate above example on the command line, run:

```bash
$ cue eval app.cue

deployment: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        namespace: "default"
// ...snip...
```

Now that we can build basic configuration, let's see how to use it with something like kubectl or [Carvel's kapp](/kapp). Neither kubectl nor kapp will look inside top level keys like `service` and `deployment` which contain Kubernetes resources, yet somehow we need to let tools know what to deploy. Fortunately we can use the Kubernetes resource `List` to combine multiple resources into one:

`resources.cue`:
```
package app

all: {
    apiVersion: "v1"
    kind: "List"
    items: [deployment, service]
}
```

Notice how contents of `deployment` and `service` fields were pulled in into `items` array. CUE allows to reference other parts of the data structure being built by field names (as long as it's unambiguous) even if it's split across multiple files.

```bash
$ cue eval resources.cue app.cue --expression all --out yaml

apiVersion: v1
kind: List
items:
  - apiVersion: apps/v1
    kind: Deployment
    metadata:
# ...snip...
```

`--expression all` flag allows to select only a portion of the result to output (content of the `all` key in this case), and `--out yaml` forces CUE to generate YAML output instead of default CUE output.

To combine it with kubectl or kapp, simply pipe it in:

```bash
$ cue eval resources.cue app.cue --expression all --out yaml | kubectl apply -f-
# or
$ cue eval resources.cue app.cue --expression all --out yaml | kapp deploy -a my-app -f- -y

Target cluster 'https://192.168.99.219:8443' (nodes: minikube)

Changes

Namespace  Name        Kind        Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  -    create  -       reconcile  -   -
^          simple-app  Service     -    create  -       reconcile  -   -

Op:      2 create, 0 delete, 0 update, 0 noop, 0 exists
Wait to: 2 reconcile, 0 delete, 0 noop

3:50:04PM: ---- applying 2 changes [0/2 done] ----
3:50:04PM: create deployment/simple-app (apps/v1) namespace: default
3:50:04PM: create service/simple-app (v1) namespace: default
...snip...
```

As you might have already figured, it's easy to incorporate other Carvel tools such as [kbld](/kbld) into such workflow once configuration is exported to YAML. For example, to build container images or resolve images to their digests before getting them deployed:

```bash
$ cue eval . -e all --out yaml | kbld -f- | kapp deploy -a my-app -f- -y
```

### CUE provided type safety

Even within a simple Kubernetes configuration, it's possible to make silly mistakes such as specifying a wrong key and thinking that particular setting is applied whereas it's actually ignored. To solve this problem one has to validate configuration against a schema, but at which point should this schema check be done?

For Kubernetes configuration specifically there are multiple possible answers:
- Configuration can be checked by the Kubernetes API server (but depending on a type of mistake server may not even catch it e.g. unknown keys are ignored with default settings though there is now a feature to enable [server side unknown field validation](https://github.com/kubernetes/enhancements/tree/master/keps/sig-api-machinery/2885-server-side-unknown-field-validation))
- Configuration can be checked after it has been generated but before it was sent to a Kubernetes server with tools such as [kubeval](https://kubeval.instrumenta.dev/)
- Configuration can be checked as part of generation (and perhaps it's worth to mention that depending on configuration tool's capabilities not all evaluation branches might be type checked potentially leaving some configuration unchecked until it's "enabled")

CUE is one of the tools that allows to specify schema and use it _while_ building configuration. In fact, it even blurs the line between concept of types and values, making types valid values. Let's take a look a small example:

```
name: "Jess"
pets: 5

name: string
pets: >1
```

`name` field is specified twice but in the first case it carries a concrete value `"Jess"` and in the second it is defined as type `string`. For CUE to decide how to "merge" these two values together it needs to have a clear set of rules which are defined by [CUE's value hierarchy](https://cuelang.org/docs/concepts/logic/#the-value-lattice). In short, more generic values (e.g. `bool`, string of 5+ runes) are closer to the top, and more concrete/specific values (e.g. `"Jess"`, `5`) are closer to the bottom. Merging always must traverse from top to bottom, so as your value turns more specific you can only "merge" it with even more specific values. (See excellent illustrations on the page linked above.)

This system allows configuration to be organized across multiple files (their evaluation order is not important!) with a gurantee that each field will not be unintentially overriden since it must resolve to a single value that is acceptable to all definitions.

When working with Kubernetes, configuration quickly turns non-trivial so here is an example of how to build more complex types by defining schemas for structs:

```
#Pod: {
    #TypeMeta
    metadata?: #ObjectMeta
    spec?: #PodSpec
}

#TypeMeta: {
    kind?: string
    apiVersion?: string
}

#ObjectMeta: {
    name?: string
    generateName?: string
    namespace?: string
    selfLink?: string
    resourceVersion?: string
    generation?: int64
    deletionGracePeriodSeconds?: null | int64
    labels?: {[string]: string}
    annotations?: {[string]: string}
    finalizers?: [...string]
    // skipped some more complex fields
}

#PodSpec: {
    // skipped
}

my_pod: #Pod & {
  kind: "Pod"
  apiVersion: "v1"
  metadata: {
    name: "my-pod"
    labels: {
      "corp.com/special": ""
    }
  }
}
```

Few notes on what's happening above:
- `#` starts off definitions (take a look at how to values are "merged" together with `&` e.g. `#Pod & { ... }`)
- Embedding of definitions is Go-inspired (e.g. `#TypeMeta` within `#Pod`)
- Fields ending with `?` are optional
- `my_pod` value is type checked against `#Pod` definition so any deviation from what's allowed by the definition would be considered to be an error by. This ultimately means that you cannot produce configuration that's invalid if your definitions are correct.

I did cheat a little bit and copy-pasted and sightly simplified definitions of `#TypeMeta` and `#ObjectMeta`, but where did I get them from? Surely, authoring Kubernetes configuration should not involve having to manually write out definitions of all Kubernetes APIs...

### Organizing configuration in modules and packages

Now that we have a way to define various types, naturally we would want to reuse them in multiple places. Core Kubernetes APIs are defined within [https://github.com/kubernetes/api](https://github.com/kubernetes/api) as Go files. Since we are working with them from CUE we need a way to import all of these Go types as CUE definitions. The process could probably be simplified but this at least how I got what I needed:

- Within your configuration directory, `go mod init corp.com/api-example`

- Add `tools.go` that depends on Kubernetes APIs and run `go mod tidy` (at this point you pulled Go version of Kubernetes APIs)

    ```go
    package main
    import (
        _ "k8s.io/api/core/v1"
        _ "k8s.io/api/apps/v1"
    )
    ```

- Within same directory, run `cue mod init corp.com/api-example` to initialize your [CUE module](https://cuelang.org/docs/concepts/packages/#modules). Modules are quite similar to Go modules and allow to give a name to a set of configuration files. They could be later imported under that name. You also have to have be within a module to import somebody else's modules.

- Now run `cue get go k8s.io/api/core/v1` and `cue get go k8s.io/api/apps/v1` to import Kubernetes API as CUE modules. You can find results of the import inside nested `cue.mod/gen/k8s.io/` directory. Take a look at `cue.mod/gen/k8s.io/api/core/v1/types_go_gen.cue` for example and find `#Pod` definition that I copy-pasted earlier.

Now that we have imported core Kubernetes APIs as CUE definitions, we can actually import these modules in our own configuration files. Let's modify our original Deployment and Service to take advantage of these new types:

`app.cue` (add to the same configuration directory)
```
package app

import (
    corev1 "k8s.io/api/core/v1"
    appsv1 "k8s.io/api/apps/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

deployment: appsv1.#Deployment & {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        namespace: "default"
        name:      "simple-app"
    }
    spec: {
        replicas: 2
        // Try to uncomment this typo-ed field and see the error you'd get
        // replica: 10
        selector: matchLabels: "simple-app": ""
        template: {
            metadata: labels: "simple-app": ""
            spec: containers: [{
                name:  "simple-app"
                image: "docker.io/dkalinin/k8s-simple-app"
                env: [{
                    name:  "HELLO_MSG"
                    value: "stranger"
                }]
            }]
        }
    }
}

service: corev1.#Service & {
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        namespace: "default"
        name:      "simple-app"
    }
    spec: {
        ports: [{
            port:       80
            targetPort: 80
        }]
        selector: "simple-app": ""
    }
}

all: metav1.#List & {
    apiVersion: "v1"
    kind: "List"
    items: [deployment, service]
}
```

Let's apply this configuration to our cluster, but this time, it's all type checked by CUE long before it makes it into a Kubernetes cluster (I've set `replicas` to `2` this time to make kapp diff a bit more interesting):

```bash
$ cue eval . --expression all --out yaml | kapp deploy -a my-app -f- -c -y

Target cluster 'https://192.168.99.219:8443' (nodes: minikube)

@@ update deployment/simple-app (apps/v1) namespace: default @@
  ...
103,103   spec:
    104 +   replicas: 2
104,105     selector:
105,106       matchLabels:

Changes

Namespace  Name        Kind        Age  Op      Op st.  Wait to    Rs  Ri
default    simple-app  Deployment  21h  update  -       reconcile  ok  -

Op:      0 create, 0 delete, 1 update, 0 noop, 0 exists
Wait to: 1 reconcile, 0 delete, 0 noop

1:27:47PM: ---- applying 1 changes [0/1 done] ----
1:27:47PM: update deployment/simple-app (apps/v1) namespace: default
1:27:47PM: ---- waiting on 1 changes [0/1 done] ----
1:27:47PM: ongoing: reconcile deployment/simple-app (apps/v1) namespace: default
1:27:47PM:  ^ Waiting for generation 12 to be observed
1:27:47PM:  L ok: waiting on replicaset/simple-app-6688c6bd67 (apps/v1) namespace: default
1:27:47PM:  L ongoing: waiting on pod/simple-app-6688c6bd67-flwmn (v1) namespace: default
1:27:47PM:     ^ Pending
...snip...
```

Since CUE is oblivious to how contents of `cue.mod` directory have been populated, one can use [Carvel's vendir](/vendir) to manage contents of `cue.mod/pkg`. For example, shared Git repository may contain generated Kubernetes APIs modules and all other projects (in their own Git repositories) just use vendir to pull in those modules into `cue.mod/pkg`. As a side note, I would strongly recommend committing entire configuration directory including `cue.mod` directory (and any downloaded content by vendir inside of it) so your Git repository always contains a complete snapshot of pieces needed to produce final configuration.

### Continuously deploying CUE configuration with kapp-controller

Hopefully we've shared enough above on how to use CUE CLI in combination with Carvel tools locally or in your CI (e.g. take a look on how to set up [GitHub Actions with OIDC on GKE](/blog/kapp-deploy-oidc-gke/)) to easily deploy your Kubernetes workloads. For those who prefer to have an on-cluster controller continuously reconciling against a source like a Git repo or an OCI registry, CUE can be easily used with [Carvel's kapp-controller](/kapp-controller).

Once you have [kapp-controller installed](/kapp-controller/docs/v0.42.0/install/), following App CR example shows how system can be configured to fetch from a Git repository (in this case GitHub Gist service), template configuration with CUE and finally deploy it with kapp (same steps we have done above but just happening on the cluster, continuously):

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: simple-app
  namespace: default
spec:
  serviceAccountName: simple-app-sa
  fetch:
  - git:
      # includes example from the beginning of the post;
      # try using your own Git repo with a latter example
      # that uses typed Kuberentes APIs
      url: https://gist.github.com/cppforlife/48f41372cdc11dc7113f295377ef2074
      ref: origin/main
  template:
  - cue:
      outputExpression: "all"
  deploy:
  - kapp: {}
```

Internally, kapp-controller will just execute `cue export . --out yaml --expression all` to assemble configuration into one stream and pass it on to kapp.

If you want to give above App CR a try, use [following RBAC setup](https://gist.githubusercontent.com/cppforlife/0dfde80e93933a62ae10a665baba64f8/raw/4f290fea6e7d07d1d4ce47d2b9ad11c5f6a9633d/config.yml) for simple-app-sa ServiceAccount referenced in `spec.serviceAccountName`.

Once you've got a hang of App CR basics, it becomes pretty simple to take advantage of other generic kapp-controller features with CUE, for example, loading [Mozilla sops + age](https://github.com/mozilla/sops) encrypted environment specific configuration (stored in Git repository) into your CUE templates as inputs:

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: simple-app
  namespace: default
spec:
  serviceAccountName: simple-app-sa
  fetch:
  - git:
      url: https://gist.github.com/cppforlife/3506224cb7b681e283376cd061b5bfc8
      ref: origin/main
  template:
  - sops:
      age:
        privateKeysSecretRef:
          name: age-decrypt
  - cue:
      inputExpression: "config:"
      outputExpression: "all"
      valuesFrom:
      - path: vals.yml
  - kbld: {}
  deploy:
  - kapp: {}
---
apiVersion: v1
kind: Secret
metadata:
  name: age-decrypt
  namespace: default
stringData:
  key.txt: |
    # public key: age1s3z9duz8c856y6qwtquhcqt6svu5pzctycvcz8nw08es2n59qffs7usgr3
    AGE-SECRET-KEY-19QRN8ST7VH4TPXM6HFPGLAR69NZU2N6M4JG8YHAM4X47KHCZM8JSCQRCH9
```

Here is what will happen once above App CR is on the cluster:
- First, Git repo is fetched
- Then, sops template step decrypts all files with `*.sops.yml` extension and just turns them into `*.yml` extension
- Next, CUE template step picks up decrypted configuration (`vals.yml`) and feeds it into CUE execution as a value under `config:` field (take a look at how [app.cue](https://gist.github.com/cppforlife/3506224cb7b681e283376cd061b5bfc8#file-app-cue-L3-L6) defines what can be accepted as input -- `#Config` defines `hello_msg` field must be a string, and no other keys are allowed)
- [Carvel's kbld](/kbld) template step ensures that all container images are referenced by their digest
- finally, kapp deploys produced resources

These were two short and sweet examples of how to use CUE and kapp-controller together as part of your GitOps workflow. And let us know if you are interested to learn how to turn your App CR into a Package CR so that you can easily distribute your CUE templates as Carvel packages (with help of [Carvel's imgpkg](/imgpkg)) but for now -- that's a wrap.

## Join us on Slack and GitHub

We want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace and connect with over 1000+ Carvel users.
* Find us on [GitHub]({{% named_link_url "github_url" %}}). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you!
