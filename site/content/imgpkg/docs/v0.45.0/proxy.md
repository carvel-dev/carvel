---
aliases: [/imgpkg/docs/latest/proxy]
title: Proxy
---

## Using Proxy

When using `imgpkg` to connect with a registry via a proxy  you will need to provide one of following environment variables

- `HTTP_PROXY` or `http_proxy` when using the flag `--registry-insecure`
- `HTTPS_PROXY` or `https_proxy` when the communication with the registry need to be using TLS

### No TLS example

Assuming the proxy to access the registry is located in `http://proxy.company.com`

When executing `imgpkg` do the following:
```bash
export http_proxy=http://proxy.company.com

imgpkg pull -b registry.company.com/my-image@sha256:265d4a5ed8bf0df27d1107edb00b70e658ee9aa5acb3f37336c5a17db634481e -o folder --registry-insecure
```

### TLS example

Assuming the proxy to access the registry is located in `https://proxy.company.com`

When executing `imgpkg` do the following:
```bash
export https_proxy=https://proxy.company.com

imgpkg pull -b registry.company.com/my-image@sha256:265d4a5ed8bf0df27d1107edb00b70e658ee9aa5acb3f37336c5a17db634481e -o folder
```
