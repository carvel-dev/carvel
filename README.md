![logo](https://raw.githubusercontent.com/vmware-tanzu/carvel/master/logos/CarvelLogo.png)
[![OpenSSF Best Practices](https://bestpractices.coreinfrastructure.org/projects/7746/badge)](https://bestpractices.coreinfrastructure.org/projects/7746)

# Carvel

Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.

This is a list of repos associated with the [Carvel](https://carvel.dev) project.

* [ytt](https://github.com/vmware-tanzu/carvel-ytt) - Template and overlay Kubernetes configuration via YAML structures, not text documents
* [kapp](https://github.com/vmware-tanzu/carvel-kapp) - Install, upgrade, and delete multiple Kubernetes resources as one "application"
* [kbld](https://github.com/vmware-tanzu/carvel-kbld) - Build or reference container images in Kubernetes configuration in an immutable way
* [imgpkg](https://github.com/vmware-tanzu/carvel-imgpkg) - Bundle and relocate application configuration (with images) via Docker registries
* [kapp-controller](https://github.com/vmware-tanzu/carvel-kapp-controller) - Capture application deployment workflow in App CRD. Reliable GitOps experience powered by kapp.
* [vendir](https://github.com/vmware-tanzu/carvel-vendir) - Declaratively state what files should be in a directory.
* [secretgen-controller](https://github.com/vmware-tanzu/carvel-secretgen-controller) - Provides CRDs to specify what secrets need to be on a cluster (generated or not).

Experimental:

* [kwt](https://github.com/vmware-tanzu/carvel-kwt)
* [terraform-provider-carvel](https://github.com/vmware-tanzu/terraform-provider-carvel)

Installation:

* [homebrew-carvel](https://github.com/vmware-tanzu/homebrew-carvel)
* [carvel-docker-image](https://github.com/vmware-tanzu/carvel-docker-image)
* [asdf-carvel](https://github.com/vmware-tanzu/asdf-carvel)
* [carvel-setup-action](https://github.com/vmware-tanzu/carvel-setup-action)

Plugins:

* [ytt.vim](https://github.com/vmware-tanzu/ytt.vim)
* [vscode-ytt](https://github.com/vmware-tanzu/vscode-ytt)

Examples:

* [carvel-simple-app-on-kubernetes](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes)
* [carvel-ytt-library-for-kubernetes](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes)
* [carvel-ytt-library-for-kubernetes-demo](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes-demo)
* [carvel-guestbook-example-on-kubernetes](https://github.com/vmware-tanzu/carvel-guestbook-example-on-kubernetes)

See what's planned in [our backlog](https://github.com/orgs/carvel-dev/projects/1).

---
# Join the Community and Make Carvel Better

Carvel is better because of our contributors and maintainers. It is because of you that we can bring great software to the community. Please join us during our online community meetings. Details can be found on our [Carvel website](https://carvel.dev/community/).

You can chat with us on Kubernetes Slack in the [#carvel channel](https://kubernetes.slack.com/archives/CH8KCCKA5) and follow us on Twitter at [@carvel_dev](https://twitter.com/carvel_dev).

Note: If aren’t already a member on the Kubernetes Slack workspace, please first [request an invitation](https://slack.k8s.io/) to gain access.

Keep up to date on all the Carvel news by joining our [mailing list](https://lists.cncf.io/g/cncf-carvel-users/join).

Check out which organizations are using and contributing to Carvel: [Adopter's list](https://github.com/vmware-tanzu/carvel/blob/develop/ADOPTERS.md)

We intend to publish new Carvel content weekly, if you're interested in contributing [please sign-up here](processes/weekly-content-sharing.md).
