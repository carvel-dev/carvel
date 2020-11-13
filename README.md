# Website for [Carvel](https://carvel.dev/)

##### Prerequisites
We use both [Hugo](https://github.com/gohugoio/hugo) and [Netlify](https://www.netlify.com/products/dev/#how-it-works) 
to build and serve the site.
* macOS: 
   * `brew install hugo`
   * `npm install netlify-cli -g`
* Windows: 
   * `choco install hugo-extended -confirm`
   * `npm install netlify-cli -g`


#### Serve the site using Netlify dev
We use Netlify to redirect some pages of the site via the `_redirects` file, you can preview these redirects locally 
using netlify dev.

```
netlify dev
```
View the site at http://localhost:8888

#### Serve Hugo Site
To view a limited view of the site without path redirects use hugo:
```
hugo server --disableFastRender
```
View the site at http://localhost:1313

### Test content
this will be removed
