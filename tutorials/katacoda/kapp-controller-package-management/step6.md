## Creating a Package: Structuring our contents
We'll create an [imgpkg bundle](https://carvel.dev/imgpkg/docs/latest/resources/#bundle)
that contains the package contents: the configuration (config.yml and values.yml from the previous step) and a reference to the greeter app image (docker.io/dkalinin/k8s-simple-app@sha256:...).

The [package bundle format](https://carvel.dev/kapp-controller/docs/latest/packaging/#package-bundle-format) describes the purpose of each directory 
used in this section of the tutorial as well as general recommendations.

Let's create a directory with our configuration files:
```
mkdir -p package-contents/config/
cp config.yml package-contents/config/config.yml
cp values.yml package-contents/config/values.yml
```{{execute}}

Once we have the configuration figured out, let’s use kbld to record which container images are used:
```
mkdir -p package-contents/.imgpkg
kbld -f package-contents/config/ --imgpkg-lock-output package-contents/.imgpkg/images.yml
```{{execute}}

For more on using kbld to populate the .imgpkg directory with an ImagesLock, and why it is useful, see the [imgpkg docs on the subject](https://carvel.dev/imgpkg/docs/latest/resources/#imageslock-configuration).

Once these files have been added, our package contents bundle is ready to be pushed!

For the purpose of this tutorial, we will run an unsecured local docker
registry. In the real world please be safe and use appropriate security
measures.

`docker run -d -p 5000:5000 --restart=always --name registry registry:2`{{execute}}

From the terminal we can access this registry as `localhost:5000` but within the
cluster we'll need the IP Address. To emphasize that you would
normally use a repo host such as dockerhub or harbor we will store the IP
address in a variable:

```
export REPO_HOST="`ifconfig | grep -A1 docker | grep inet | cut -f10 -d' '`:5000"
```{{execute}}

Now we can publish our bundle to our registry:

`imgpkg push -b ${REPO_HOST}/packages/simple-app:1.0.0 -f package-contents/`{{execute}}


You can verify that we pushed something called `packages/simple-app` by checking the Docker registry catalog:

`curl ${REPO_HOST}/v2/_catalog`{{execute}}

