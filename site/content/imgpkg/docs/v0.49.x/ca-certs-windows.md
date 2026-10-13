---
aliases: [/imgpkg/docs/latest/ca-certs-windows]
title: CA Certs on Windows
---

## Known issue verifying certificates on Windows

If you are using imgpkg v0.19.0 or earlier, and use imgpkg with a registry over https, you will likely encounter the following error:
```
imgpkg: Error: Fetching image:
  Get "https://some.registry/v2/": x509: certificate signed by unknown authority
```

imgpkg v0.20.0+ supports loading Windows root ca certs. Meaning, that imgpkg is able to verify registry certificates signed by a trusted certificate authority!

## Known issue providing custom ca certificates on Windows

imgpkg allows specifying the `--registry-ca-cert-path` flag as a way to add custom ca certificates to use when verifying a registry server certificate.

However, on Windows, the entire set of ca certificates to use during verify is loaded from the flag (Windows root ca store is skipped in this case). 
Meaning that if you are targeting multiple registries, and some are signed with a trusted certificate authority and others signed with a custom ca certificate, 
both ca certificates will need to be provided. (via the `--registry-ca-cert-path` flag)

An example workflow:
1. Build a single ca certificate file (containing multiple ca certificates) from a trusted source. e.g. [extract ca certs provided by Mozilla](https://github.com/curl/curl/blob/4d2f8006777d6354d9b62eae38ebd0a0256d0f94/lib/firefox-db2pem.sh)
1. Provide that single ca certificate file to imgpkg. `--registry-ca-cert-path ./mozilla-ca-certs.pem`
1. Provide any additional custom ca certificates to imgpkg. `--registry-ca-cert-path ./dev-registry.pem`

