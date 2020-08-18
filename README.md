# k14s.io

[https://k14s.io](https://k14s.io) website.

## Development

```bash
./hack/build.sh

# include goog analytics in 'k14s' command for https://carvel.dev
# (goog analytics is _not_ included in release binaries)
BUILD_VALUES=./hack/build-values-carvel-dev.yml ./hack/build.sh
```

`build.sh` depends on [ytt](https://github.com/k14s/ytt).
