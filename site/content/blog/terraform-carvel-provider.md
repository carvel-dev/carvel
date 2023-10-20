---
title: "Using Carvel Terraform Provider to manage Kubernetes workloads"
slug: terraform-carvel-provider
date: 2021-11-29
author: Soumik Majumder
excerpt: "Looking to leverage Carvel tools to manage workloads on Kubernetes while setting up your platform using Terraform? Carvel's Terraform provider has your back"
image: /img/logo.svg
tags: ['Soumik Majumder']
---

The Carvel tools are designed to empower our users to manage their Kubernetes workloads effectively. We realise that engineers leveraging Terraform to declaratively define their platforms might want to use Carvel tools to set up applications and workloads on their Kubernetes clusters in a predictable manner. Carvel's [terraform provider](https://github.com/carvel-dev/terraform-provider-carvel) allows engineers to do _exactly_ this using Terraform configurations.

In this blog, we will be using the provider to deploy this [sample guestbook application](https://github.com/carvel-dev/terraform-provider-carvel/tree/develop/examples/guestbook) on a Kubernetes cluster.

Do make a copy of the folder in your working directory if you want to follow along!

## Setting things up
The [Carvel provider](https://registry.terraform.io/providers/carvel-dev/carvel/latest) is published on the Terraform registry.

The resources used, require their respective binaries to be available on `$PATH`. We will be using _ytt_ to apply an overlay to our manifests and then deploy the resources using _kapp_. We can make the Carvel binaries available by using our install script

```bash
$ wget -O- https://carvel.dev/install.sh | bash
# or with curl...
$ curl -L https://carvel.dev/install.sh | bash
```

See our [**Install** section](/) for alternative installation methods.

If you do not have Terraform set up on your system, you can refer to the [installation page](https://learn.hashicorp.com/tutorials/terraform/install-cli) in the official docs for the same.

We will be using the latest version of the Carvel provider available as of today.
We declare this requirement in `main.tf`

```terraform
terraform {
  required_providers {
    carvel = {
      source = "carvel-dev/carvel"
      version = "0.10.0"
    }
  }
}
```
We will then define our Terraform configuration which sets up our resources on the cluster in the file `app.tf`
## Connecting to the cluster
The _kapp_ resource requires the `kubeconfig` attribute to connect to the cluster. We will be asking the _kapp_ resource to use the config used by _kubectl_ in the same environment. 

Look [here](https://github.com/carvel-dev/terraform-provider-carvel/blob/develop/docs/provider.md) for more ways of authenticating while connecting to a cluster.

```terraform
provider "carvel" {
  kapp {
    kubeconfig {
      from_env = true
    }
  }
}
```
## Overlaying using _ytt_
We can use [_ytt_](https://github.com/carvel-dev/ytt) to template and apply overlays to our manifests, this allows our manifests to be dynamic. In this blog, we will be asking _ytt_ to apply an overlay that ensures that all Deployment resources spawn one replica.

```terraform
data "carvel_ytt" "guestbook" {
  files = ["ytt-config"]
  ignore_unknown_comments = true

  config_yaml = <<EOF
    #@ load("@ytt:overlay", "overlay")
    #@overlay/match by=overlay.subset({"kind":"Deployment"}),expects="1+"
    ---
    spec:
      replicas: 1
  EOF
}
```

## Deploying with _kapp_    
[_kapp_](https://github.com/carvel-dev/kapp) helps us deploy resources to our clusters in a safe and predicatable manner, apply them in a certain order and then wait for the resources to reach their desired state among other things. We will be asking _kapp_ to group the resources declared in the manifest as an application called "guestbook" and deploy it to the default namespace. The manifest consumed is the one produced by the _ytt_ data source.
```terraform
resource "carvel_kapp" "guestbook" {
  app = "guestbook"
  namespace = "default"
  config_yaml = data.carvel_ytt.guestbook.result
}
```

## Get, Set, Deploy!
At this point we can install the provider:
```bash
$ terraform init
```
and then validate our configuration:
```bash
$ terraform validate
```

For readers following along, the working directory looks something like this at this point:
```bash
├── app.tf
├── main.tf
├── terraform.tfstate
├── terraform.tfstate.backup
└── ytt-config
    ├── frontend.yaml
    ├── guestbook-all-in-one.yaml
    └── redis-slave.yaml

```
The final contents of `app.tf` being:
```terraform
terraform {
  required_providers {
    carvel = {
      source = "carvel-dev/carvel"
      version = "0.10.0"
    }
  }
}

provider "carvel" {
  kapp {
    kubeconfig {
      from_env = true
    }
  }
}

data "carvel_ytt" "guestbook" {
  files = ["ytt-config"]

  # Configure all deployments to have 1 replica
  config_yaml = <<EOF
    #@ load("@ytt:overlay", "overlay")
    #@overlay/match by=overlay.subset({"kind":"Deployment"}),expects="1+"
    ---
    spec:
      replicas: 1
  EOF
}

resource "carvel_kapp" "guestbook" {
  app = "guestbook"
  namespace = "default"
  config_yaml = data.carvel_ytt.guestbook.result
}
```

We can now create the declared resources.
```bash
$ terraform create
```

Terraform creates the `carvel_kapp.guestbook` resource and waits for it to reach the desired state. (Thanks _kapp_!).
We can run:
```bash
$ kubectl get deployment frontend -o yaml
```
To verify that each Deployment resource spawns one replica even thought the [original manifest](https://github.com/carvel-dev/terraform-provider-carvel/blob/develop/examples/guestbook/ytt-config/frontend.yaml) specified three replicas. (Thanks to _ytt_'s overlay!)

## That's cool! How does this make my life easier?
If you are using Terraform to declaratively provision GKE or EKS clusters and developers working on your platform need to be able deploy workloads which use `cert-manager` to allow secure connections. You can use the _kapp_ resource to install `cert-manager` on your cluster as a part of your Terraform configuration.

This stands true for other resources you would want to deploy on your cluster after provisioning it while the _ytt_ data source allows you to template and overlay your manifests on the go.

We would love to know how you are using the Carvel tools and our Terraform provider on [this thread](https://github.com/carvel-dev/carvel/issues/213)!

## Join us on Slack and GitHub

We are excited about this new adventure and we want to hear from you and learn with you. Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/carvel-dev/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how to attend.

We look forward to hearing from you and hope you join us in building a strong packaging and distribution story for applications on Kubernetes!
