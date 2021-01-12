![logo](https://raw.githubusercontent.com/vmware-tanzu/carvel/master/logos/CarvelLogo.png)

# Website for [carvel.dev](https://carvel.dev/)

### Join the Community and Make Carvel Better
Carvel is better because of our contributors and maintainers. It is because of you that we can bring great software to the community.
Please join us during our online community meetings ([Zoom link](http://community.klt.rip/)) every other Wednesday at 12PM ET / 9AM PT and catch up with past meetings on the [VMware YouTube Channel](https://www.youtube.com/playlist?list=PL7bmigfV0EqQ_cDNKVTIcZt-dAM-hpClS).
Join [Google Group](https://groups.google.com/g/carvel-dev) to get updates on the project and invites to community meetings.
You can chat with us on Kubernetes Slack in the #carvel channel and follow us on Twitter at @carvel_dev.

Check out which organizations are using and contributing to Carvel: [Adopter's list](https://github.com/vmware-tanzu/carvel/ADOPTERS.md)

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
