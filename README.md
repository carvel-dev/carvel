![logo](https://raw.githubusercontent.com/vmware-tanzu/carvel/master/logos/CarvelLogo.png)

# Carvel
 
Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.
 
Carvel eases lifecycle management of your Kubernetes workloads. The origin of Carvel begins with Dmitriy Kalinin and Nima Kaviani not being satisfied with existing tools to deploy Kubernetes workloads. These tools were monolithic, error-prone, and hard to debug. Carvel promises a better way, one that extracts common app configuration into a library for use by all your applications.
 
Carvel is built with UNIX philosophy in mind. We believe each tool should be optimized for a single purpose, and have clear boundaries. This allows you to weave Carvel into your Kubernetes environment however you want. It’s up to you to choose one element of Carvel, or the entire set of tools.
 
This is a list of repos associated with the [Carvel](https://carvel.dev) project.
 
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
* [vscode-ytt](https://github.com/vmware-tanzu/vscode-ytt)
 
Examples:
 
* [carvel-simple-app-on-kubernetes](https://github.com/vmware-tanzu/carvel-simple-app-on-kubernetes)
* [carvel-ytt-library-for-kubernetes](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes)
* [carvel-ytt-library-for-kubernetes-demo](https://github.com/vmware-tanzu/carvel-ytt-library-for-kubernetes-demo)
* [carvel-guestbook-example-on-kubernetes](https://github.com/vmware-tanzu/carvel-guestbook-example-on-kubernetes)
 
---
# Join the Community and Make Carvel Better
Carvel is better because of our contributors and maintainers. It is because of you that we can bring great software to the community.
Please join us during our online community meetings and office hours. Details can be found on our [Carvel website](https://carvel.dev/community/).
 
You can chat with us on Kubernetes Slack in the [#carvel channel](https://kubernetes.slack.com/archives/CH8KCCKA5) and follow us on Twitter at [@carvel_dev](https://twitter.com/carvel_dev). <p>Note: If you aren’t already a member on the Kubernetes Slack workspace, please first <a href="https://slack.k8s.io/request" target="_blank">request an invitation</a> to gain access.</p>
 
Check out which organizations are using and contributing to Carvel: [Adopter's list](https://github.com/vmware-tanzu/carvel/blob/develop/ADOPTERS.md)
