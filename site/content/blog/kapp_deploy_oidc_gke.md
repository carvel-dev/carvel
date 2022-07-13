---
title: "kapp deploy on GCP using keyless authentication(OIDC)"
slug: kapp-deploy-oidc-gke
date: 2022-07-14
author: Yash Sethiya
excerpt: "Use github action OIDC token to authenticate on GCP and deploy using kapp on GKE"
image: /img/logo.svg
tags: ['kapp', 'oidc', 'keyless-authentication']
---

### Who

This article can helpful for any one who wants to create the Github Action workflow to authenticate with GCP and how to deploy kubernetes manifest on GKE using kapp. 

### Why

Traditionally, authenticating from GitHub Actions to Google Cloud required exporting and storing a long-lived JSON service account key, turning an identity management problem into a secrets management problem. 

But now, with GitHub's introduction of OIDC tokens into GitHub Actions Workflows, you can authenticate from GitHub Actions to Google Cloud using OIDC (Workload Identity Federation), removing the need to export a long-lived JSON service account key.

### Benefits

By updating workflows to use OIDC tokens, we can adopt the following good security practices:

- No cloud secrets: No need to duplicate cloud credentials as long-lived GitHub secrets. Instead, you can configure the OIDC trust on GCP, and then update workflows to request a short-lived access token from the cloud provider through OIDC.
- Authentication and authorization management: Will have more granular control over how workflows can use credentials and also you can control access to cloud resources.
- Rotating credentials: With OIDC, cloud provider issues a short-lived access token that is only valid for a single job, and then automatically expires.

### How

Now we will see how we can use GitHub Action – [auth](https://github.com/google-github-actions/auth) to set up and configure authentication to Google Cloud. We need to perform the following configurations on GCP - 

1. Create new Workload Identity Pool (IAM -> Workload Identity Federation -> Workload Indentity Pool) and add a OIDC Provider to it with Issuer URL as `https://token.actions.githubusercontent.com`.
2. Configure the Attribute mapping and conditions of provider.
3. Create a service account and connect Workload Identity Pool you just creted to the service account by assigned to the Workload Identity User role. For more information, see the [GCP documentation](https://cloud.google.com/iam/docs/workload-identity-federation?_ga=2.114275588.-285296507.1634918453#conditions).

To update workflows for OIDC, you will need to make two changes to your YAML:

1. Add permissions settings for the token. The job or workflow run requires a permissions setting with `id-token: write`. You won't be able to request the OIDC JWT ID token if the permissions setting for `id-token` is set to `read` or `none`.

```yaml
permissions:
  id-token: write
```

2. Use the google-github-actions/auth action to exchange the OIDC token (JWT) for a cloud access token.

```yaml
steps:
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v0.4.0'
  with:
    workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider'
    service_account: 'my-service-account@my-project.iam.gserviceaccount.com'
```

This will use the configured workload_identity_provider and service_account to authenticate future steps. Make sure to replace the value of `workload_identity_provider` with the path to your identity provider in GCP and also replace the value of `service_account` key with the name of your service account in GCP. 

### Example

Here is a sample github action which get triggered when new tag is created on the repo. It authenticate with GCP, get the GKE credentials, install carvel tools on the GKE cluster and deploy a simple app using kapp. 

```yaml
name: oidc action GCP

on:
  push:
    tags:
      - "v*"

jobs:
  Get_OIDC_ID_token:
    runs-on: ubuntu-latest

    permissions:
      id-token: 'write'
      contents: 'read'

    steps:
      # actions/checkout MUST come before auth
      - uses: 'actions/checkout@v3'

      - id: 'auth'
        name: 'Authenticate to Google Cloud'
        uses: 'google-github-actions/auth@v0.4.0'
        with:
          workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider'
          service_account: 'my-service-account@my-project.iam.gserviceaccount.com'

      - id: get-gke-credentials
        uses: google-github-actions/get-gke-credentials@v0.4.0
        with:
          cluster_name: cluster-yash
          location: us-central1-a

      - id: install-kapp
        run: |-
          wget -O- https://carvel.dev/install.sh > install.sh
          sudo bash install.sh
          kapp version

      - id: 'deploy-with-kapp'
        run: |-
          kapp deploy -a app -f simple-app.yml -y

```

Please refer to this [Github Repo](https://github.com/sethiyash/carvel-kapp-oidc-github) which contain a github action and simple-app.yml which we will deploy on GKE using kapp. 

## Join us on Slack and GitHub

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how and when to attend.


