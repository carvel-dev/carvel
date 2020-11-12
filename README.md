# Website for [Carvel](https://carvel.dev/)

##### Prerequisites

* [Hugo](https://github.com/gohugoio/hugo)
    * macOS: `brew install hugo`
    * Windows: `choco install hugo-extended -confirm`

#### Build

```bash
hugo server --disableFastRender
```

#### Serve Hugo Site

Serve site at http://localhost:1313

or

#### Serve the site using Netlify dev
We use Netlify to redirect some pages of the site via the `_redirects` file. You can preview these redirects locally using netlify dev.
* Install netlify dev
    * `npm install netlify-cli -g`
* Serve the site at http://localhost:8888
    * `netlify dev`
