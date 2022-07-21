---
title: "Kapp deploy on GCP using keyless authentication(OIDC)"
slug: kapp-deploy-oidc-gke
date: 2022-07-21
author: Yash Sethiya
excerpt: "Learn how to create the GitHub Action workflow to authenticate with GCP and to deploy Kubernetes manifest on GKE using kapp."
image: /img/logo.svg
tags: ['kapp', 'oidc', 'keyless-authentication']
---

### Who

This article can be helpful for anyone who wants to create the Github Action workflow to authenticate with GCP and to deploy Kubernetes manifest on GKE using kapp. 

### Why 

Earlier, we used to authenticate to Google Cloud from GitHub Actions by storing JSON service account key in GitHub Secrets.

Now, that GitHub introduced OIDC tokens into GitHub Actions Workflows, you can authenticate from GitHub Actions to Google Cloud using OIDC (Workload Identity Federation), removing the need to export a long lived JSON service account key. Please refer [here](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#benefits-of-using-oidc) to know more about the benefits of using OIDC. 

### How

Now we will see how we can use GitHub Action – [auth](https://github.com/google-github-actions/auth) to set up and configure authentication to Google Cloud. We need to perform the following configurations on GCP - 

1. Create a new Workload Identity Pool (IAM -> Workload Identity Federation -> Workload Identity Pool) and add an OIDC Provider to it with Issuer URL as `https://token.actions.githubusercontent.com`.
2. Configure the Attribute mapping and conditions of the provider.
3. Create a service account and connect Workload Identity Pool you just created to the service account by assigning Workload Identity User role. For more information, see the [GCP documentation](https://cloud.google.com/iam/docs/workload-identity-federation).

To update workflows for OIDC, you will need to make two changes to your GitHub Action YAML:

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

Here is a sample GitHub Action which gets triggered when a new tag is created on the repo. It authenticates with GCP, gets the GKE credentials, installs Carvel tools on the GKE cluster, and deploys a simple app using kapp.  

```yaml
name: Deploy using kapp

on:
  push:
    tags:
      - "v*"

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      id-token: 'write'

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
        uses: vmware-tanzu/carvel-setup-action@v1
        with:
          only: kapp
         
      - id: 'deploy-with-kapp'
        run: |-
          kapp deploy -a app -f simple-app.yml -y
          kapp ls
```

We created this [sample GitHub repo](https://github.com/k14s/kaap-deploy-oidc) for reference to help guide you, which contains a GitHub Action and simple-app.yml which we deploy on GKE using kapp as mentioned above. Thanks for following along! We hope you found this helpful.

## Join us on Slack and GitHub

We are excited to hear from you and learn with you! Here are several ways you can get involved:

* Join Carvel's slack channel, [#carvel in Kubernetes]({{% named_link_url "slack_url" %}}) workspace, and connect with over 1000+ Carvel users.
* Find us on [GitHub](https://github.com/vmware-tanzu/carvel). Suggest how we can improve the project, the docs, or share any other feedback.
* Attend our Community Meetings! Check out the [Community page](/community/) for full details on how and when to attend.


