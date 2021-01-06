---
title: Development
---

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/)
- [ytt](https://github.com/vmware-tanzu/carvel-ytt)
- [pack 0.8.1](https://github.com/buildpacks/pack)

## Run Unit tests
```bash
# Run all tests
./hack/test.sh
# or run single test
./hack/test.sh -run TestLogger
```

## Run E2E tests against minikube registry
```bash
# Bootstrap k8s cluster and enable docker registry
# X.X.X.X must be replaced with your subnetmask of "minikube ip"
minikube start --driver=docker --insecure-registry=X.X.X.X/16
# Build kbld binary for testing
./hack/build.sh
# Make your env aware of the docker registry
eval $(minikube docker-env)
# Run all tests
./hack/test-all-minikube-local-registry.sh
# or run single test
./hack/test-all-minikube-local-registry.sh -run TestDockerBuildSuccessful
```

## Website build
```bash
# include goog analytics in 'kbld website' command for https://get-kbld.io
# (goog analytics is _not_ included in release binaries)
BUILD_VALUES=./hack/build-values-get-kbld-io.yml ./hack/build.sh
```

## Source Code Structure

For those interested in extending and improving kbld, below is a quick reference on the structure of the source code:

- [.github/workflows/test-gh.yml](https://github.com/vmware-tanzu/carvel-kbld/blob/develop/.github/workflows/test-gh.yml) is a Github Action that runs build and unit tests when commits are pushed
- [hack](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/hack) has build and test scripts
- [cmd/kbld](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/cmd/kbld) is the entry package for main kbld binary
- [cmd/kbld-lambda-website](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/cmd/kbld-lambda-website) is the entry package for AWS Lambda compatible binary that wraps `kbld website` command
- [pkg/kbld/cmd](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/cmd) includes all kbld CLI commands (kbld.go is root command)
- [pkg/kbld/config](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/config) describes kbld configuration resources such as Config, Sources, etc.
- [pkg/kbld/resources](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/resources) allows to parse YAML files into Resource objects 
- [pkg/kbld/image](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/image) contains set of classes that know how to "transform" image URLs (build it, resolve it to digest, tag it)
- [pkg/kbld/registry](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/registry) provides a simplified registry API client
- [pkg/kbld/search](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/pkg/kbld/search) implements YAML node searcher that finds image URLs
- [test/e2e](https://github.com/vmware-tanzu/carvel-kbld/tree/develop/test/e2e) includes e2e tests that can run against Docker registry.

## How to set up an insecure-only registry
It is occasionally necessary to test against insecure-only registries in order to ensure the commands can run against http endpoints.
Here's how we set one up on Google's Kubernetes Engine:


* Create a GKE cluster through the web GUI
* Install gcloud - https://cloud.google.com/kubernetes-engine/docs/quickstart#local-shell
* Target your cluster `gcloud container clusters get-credentials <cluster-name>`
* Create the registry deployment file, reg.yml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  labels:
    app: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry
        ports:
        - containerPort: 8080
        env:
        - name: REGISTRY_PORT
          value: "8080"
```

* Apply the deployment with `kubectl apply -f reg.yml`

* Expose it on port 5000 with
`kubectl expose deployment registry --name=registry --type=LoadBalancer --port 80 --target-port 5000 -oyaml`

* Wait until it gets an external IP (~30 seconds)

To verify that the registry is up and running:\
In [GKE](https://console.cloud.google.com/), navigate to Kubernetes Engine, then 'Services & Ingress'\
Confirm that there is an 'External load balancer' named 'registry' with an 'External Endpoint' and a link that returns a 200.\
At the bottom of the details view (click on registry), see that port forwarding is set up with a 'target port' of 5000.

That's all!  We should now be able to run regular commands against it:
`kbld relocate -f test/e2e/assets/simple-app -r <External IP>:80/<Name> --registry-insecure`