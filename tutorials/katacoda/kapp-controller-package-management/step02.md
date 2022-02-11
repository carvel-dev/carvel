## Installing kapp-controller dependencies

We'll be using [Carvel](https://carvel.dev/) tools throughout this tutorial, so first we'll install
[ytt](https://carvel.dev/ytt/), [kbld](https://carvel.dev/kbld/),
[kapp](https://carvel.dev/kapp/), [imgpkg](https://carvel.dev/imgpkg/), and [vendir](https://carvel.dev/vendir/).

Install the tools with the scripts below:

```bash
wget https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/83fffcfe99a65031b4170813acf94f8d5058b346/hack/dependencies.yml
wget https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/83fffcfe99a65031b4170813acf94f8d5058b346/hack/install-deps.sh
chmod a+x ./install-deps.sh
./install-deps.sh
```{{execute}}


