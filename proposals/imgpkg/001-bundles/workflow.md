# Making a bundle

## team builds a bundle

instead of providing users with tgz with config, we want to serve that artifact off of registry

```bash
# for example, in CI
cd app/
kbld -f <(ytt ...) --lock-output .imgpkg/images.yml # build images.yml as we do today
imgpkg push -b registry.vendor.com/app-staging:v0.5.0 -f .

# relocate all external depedencies into registry.com
imgpkg copy -b registry.vendor.com/app-staging:v0.5.0 --to-repo registry.vendor.com/app-prod
```

---
# Consuming bundle

## without relocation

(see below for relocation)

```bash
# potentially auth to registry for pulling bundle
export IMGPKG_REGISTRY_HOSTNAME=registry.com
export IMGPKG_REGISTRY_USERNAME=foo
export IMGPKG_REGISTRY_PASSWORD=bar

imgpkg pull -b registry.vendor.com/app-prod:v0.5.0 -o /tmp/app

cd /tmp/app
edit /tmp/app-values/values.yml # create specific data values
kapp deploy -a cf -f <(ytt -f config/ -f /tmp/app-values/values.yml | kbld -f .imgpkg/images.yml)
```


## ... or with relocation first

```bash
# potentially auth to registry for pushing bundle
export IMGPKG_REGISTRY_HOSTNAME=registry.customer.com
export IMGPKG_REGISTRY_USERNAME=foo
export IMGPKG_REGISTRY_PASSWORD=bar

imgpkg copy -b registry.vendor.com/app-prod:v0.5.0 --to-repo registry.customer.com/app
imgpkg pull -b registry.customer.com/app:v0.5.0 -o /tmp/app

cd /tmp/app
edit /tmp/app-values/values.yml
kapp deploy -a cf -f <(ytt -f config/ -f /tmp/app-values/values.yml | kbld -f .imgpkg/images.yml)
```


## ... or with air-gapped relocation

```bash
imgpkg copy -b registry.vendor.com/app-prod:v0.5.0 --to-tar app-v0.5.0.tar
# transport tarball to the bunker ...

# from the bunker ...
imgpkg copy --tar app-v0.5.0.tar --to-repo registry.customer.com/app
imgpkg pull -b registry.customer.com/app:v0.5.0 -o /tmp/app

cd /tmp/app
edit /tmp/app-values/values.yml
kapp deploy -a cf -f <(ytt -f config/ -f /tmp/app-values/values.yml | kbld -f .imgpkg/images.yml)
```
