# Website for [carvel.dev](https://carvel.dev)
 
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
 
- `/themes/carvel/assets/` includes SCSS
- `/themes/carvel/static/img/` includes images
- `/content/` includes content for tool docs
- `/data/` includes configuration for docs TOCs
 
More details: [Directory Structure Explained](https://gohugo.io/getting-started/directory-structure/)
