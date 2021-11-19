## Installing kapp-controller dependencies

We'll be using [Carvel](https://carvel.dev/) tools throughout this tutorial, so first we'll install 
[ytt](https://carvel.dev/ytt/), [kbld](https://carvel.dev/kbld/),
[kapp](https://carvel.dev/kapp/), [imgpkg](https://carvel.dev/imgpkg/), and [vendir](https://carvel.dev/vendir/).

Install the whole tool suite with the script below:

(Note: we are temporarily overriding kapp-controller's version to jump to ytt
0.38.0, in order to include the recent OpenAPI Schema feature in this tutorial)
```bash
wget -O- https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/fc5458fe2102d67e85116c26534a35e265b28125/hack/install-deps.sh | \
sed 's/ytt_version=v0.35.1/ytt_version=v0.38.0/' | \
sed 's/0aa78f7b5f5a0a4c39bddfed915172880344270809c26b9844e9d0cbf6437030/2ca800c561464e0b252e5ee5cacff6aa53831e65e2fb9a09cf388d764013c40d/' | \
bash
```{{execute}}


