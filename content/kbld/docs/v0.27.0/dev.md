# Development

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/)
- [ytt](https://github.com/k14s/ytt)
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

- [.github/workflows/test-gh.yml](https://github.com/k14s/kbld/blob/develop/.github/workflows/test-gh.yml) is a Github Action that runs build and unit tests when commits are pushed
- [hack](https://github.com/k14s/kbld/tree/develop/hack) has build and test scripts
- [cmd/kbld](https://github.com/k14s/kbld/blob/develop/cmd/kbld) is the entry package for main kbld binary
- [cmd/kbld-lambda-website](https://github.com/k14s/kbld/blob/develop/cmd/kbld-lambda-website) is the entry package for AWS Lambda compatible binary that wraps `kbld website` command
- [pkg/kbld/cmd](https://github.com/k14s/kbld/tree/develop/pkg/kbld/cmd) includes all kbld CLI commands (kbld.go is root command)
- [pkg/kbld/config](https://github.com/k14s/kbld/tree/develop/pkg/kbld/config) describes kbld configuration resources such as Config, Sources, etc.
- [pkg/kbld/resources](https://github.com/k14s/kbld/tree/develop/pkg/kbld/resources) allows to parse YAML files into Resource objects 
- [pkg/kbld/image](https://github.com/k14s/kbld/tree/develop/pkg/kbld/image) contains set of classes that know how to "transform" image URLs (build it, resolve it to digest, tag it)
- [pkg/kbld/registry](https://github.com/k14s/kbld/tree/develop/pkg/kbld/registry) provides a simplified registry API client
- [pkg/kbld/search](https://github.com/k14s/kbld/tree/develop/pkg/kbld/search) implements YAML node searcher that finds image URLs
- [test/e2e](https://github.com/k14s/kbld/tree/develop/test/e2e) includes e2e tests that can run against Docker registry.
- [pkg/kbld/website](https://github.com/k14s/kbld/tree/develop/pkg/kbld/website) has HTML and JS assets used by `kbld website` command and ultimately https://get-kbld.io.
