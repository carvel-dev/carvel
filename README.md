![logo](https://raw.githubusercontent.com/vmware-tanzu/carvel/master/logos/CarvelLogo.png)

# Website for [carvel.dev](https://carvel.dev/)

Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.

This is a list of repos associated with [Carvel](https://carvel.dev) project.

* [ytt](https://github.com/vmware-tanzu/carvel-ytt) - Template and overlay Kubernetes configuration via YAML structures, not text documents
* [kapp](https://github.com/vmware-tanzu/carvel-kapp) - Install, upgrade, and delete multiple Kubernetes resources as one "application"
* [kbld](https://github.com/vmware-tanzu/carvel-kbld) - Build or reference container images in Kubernetes configuration in an immutable way
* [imgpkg](https://github.com/vmware-tanzu/carvel-imgpkg) - Bundle and relocate application configuration (with images) via Docker registries
* [kapp-controller](https://github.com/vmware-tanzu/carvel-kapp-controller) - Capture application deployment workflow in App CRD. Reliable GitOps experience powered by kapp.
* [vendir](https://github.com/vmware-tanzu/carvel-vendir) - Declaratively state what files should be in a directory.

Experimental:

* [kwt](https://github.com/vmware-tanzu/carvel-kwt)
* [terraform-provider-carvel](https://github.com/vmware-tanzu/terraform-provider-carvel)
* [carvel-secretgen-controller](https://github.com/vmware-tanzu/carvel-secretgen-controller)

Installation:

* [homebrew-carvel](https://github.com/vmware-tanzu/homebrew-carvel)
* [carvel-docker-image](https://github.com/vmware-tanzu/carvel-docker-image)
* [asdf-carvel](https://github.com/vmware-tanzu/asdf-carvel)
* [carvel-setup-action](https://github.com/vmware-tanzu/carvel-setup-action)

Plugins:

* [ytt.vim](https://github.com/vmware-tanzu/ytt.vim)

Examples:

* [carvel-simple-app-on-kubernetes](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes)
* [carvel-ytt-library-for-kubernetes](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes)
* [carvel-ytt-library-for-kubernetes-demo](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes-demo)
* [carvel-guestbook-example-on-kubernetes](https://github.com/vmware-tanzu/carvel-guestbook-example-on-kubernetes)

---
## Local Development

### Prerequisites

* Install [Hugo](https://github.com/gohugoio/hugo)
    - (Note "hugo extended" is required since this site uses SCSS)
    - Prebuilt binaries: https://github.com/gohugoio/hugo/releases
    - macOS: `brew install hugo`
    - Windows: `choco install hugo-extended -confirm`

### Run locally

```bash
./hack/run.sh
```

### Serve

Serve site at [http://localhost:1313]()

### Directories

- `themes/carvel/assets/` includes SCSS
- `themes/carvel/static/img/` includes images
- `content/` includes content for tool docs
- `data/` includes configuration for docs TOCs 

More details: [Directory Structure Explained](https://gohugo.io/getting-started/directory-structure/)

### Join the Community and Make Carvel Better
Carvel is better because of our contributors and maintainers. It is because of you that we can bring great software to the community.
Please join us during our online community meetings. Details can be found on our [Carvel website](https://carvel.dev/community/).

You can chat with us on Kubernetes Slack in the #carvel channel and follow us on Twitter at @carvel_dev.

Check out which organizations are using and contributing to Carvel: [Adopter's list](https://github.com/vmware-tanzu/carvel/ADOPTERS.md)