## Installing kapp-controller dependencies

We'll be using [Carvel](https://carvel.dev/) tools throughout this tutorial, so first we'll install 
[ytt](https://carvel.dev/ytt/), [kbld](https://carvel.dev/kbld/),
[kapp](https://carvel.dev/kapp/), [imgpkg](https://carvel.dev/imgpkg/), and [vendir](https://carvel.dev/vendir/).

Install the whole tool suite with the script below:

```bash
wget -O- https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/fc5458fe2102d67e85116c26534a35e265b28125/hack/install-deps.sh | bash
```{{execute}}


