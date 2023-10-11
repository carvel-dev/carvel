---
aliases: [/kapp-controller/docs/latest/controller-config]
title: Configuring the Controller
---

kapp-controller exposes the ability to configure the controller via a
Secret (available in v0.22.0+) or ConfigMap (available in v0.14.0+), 
which kapp controller will look for and apply as part of its [startup processes](startup.md).

The controller configuration was originally only available in a ConfigMap 
format, but as of v0.22.0 it is recommended to use a Secret since there 
may be sensitive information stored in the config (e.g. proxy information including passwords).

In this configuration the user can provide the following:
- Trusted Custom CA Certificates
- Proxy configuration
- List of domains that imgpkg should interact with and should skip TLS verification

## Controller Configuration Spec

```yaml
apiVersion: v1
kind: Secret
metadata:
  # Name must be `kapp-controller-config` for kapp controller to pick it up
  name: kapp-controller-config

  # Namespace must match the namespace kapp-controller is deployed to
  namespace: kapp-controller

stringData:
  # A cert chain of trusted ca certs. These will be added to the system-wide
  # cert pool of trusted ca's (optional)
  caCerts: |
    -----BEGIN CERTIFICATE-----
    MIIEXTCCAsWgAwIBAgIQDqAvoGhrmyB/EvhjT/efWzANBgkqhkiG9w0BAQsFADA4
    MQwwCgYDVQQGEwNVU0ExFjAUBgNVBAoTDUNsb3VkIEZvdW5kcnkxEDAOBgNVBAMT
    B2Jvc2gtY2EwHhcNMjAxMjIzMTY1OTAxWhcNMjExMjIzMTY1OTAxWjA4MQwwCgYD
    VQQGEwNVU0ExFjAUBgNVBAoTDUNsb3VkIEZvdW5kcnkxEDAOBgNVBAMTB2Jvc2gt
    Y2EwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCsMTj5yHLez8jzONu1
    tv+u0dqzt8UdWCtUtHCDkIiNJIcB3PkGG7x/LvZ0bMydWeFcBq0g15tfG6N6vHnF
    4p2E9nSe0XjEEnxEkmtdpoFVPZdHTBgc6H5LOMshPH1ARWpuvBnDb87oVinIZBaf
    7BjhUQcRoGtsomk/R9Ke9FB4rMZUfuY/7CC8lDyP5Y02VeTAUimK6/WfDh3VPB3e
    vQfXKJY0Ba5s43fIdudV+fcuKDut01oKmiBL6IHLRSrZKta5mg4fgimst6nJ4xvU
    SWqYWS4yMxf6pOrTHPjbKUqXqbK4Reh+oQoE12WJZ3NvXr1GoDzt1xzTNzUpUVws
    nQm5Fo9H07mkjKeu8gOrOBQ2FqaK+eZ5FFNV7kToVQj2KVTEbLLcTrF454jhsoSd
    EOlqVUjtfxGz0dGEuy+IgMvSSjtky7eI08jdBWMiOThQvR3n0Q6TXF/wBwCEfgDa
    4eVeziaUGPXUsefR2+2ZCQ6Z31SmtUGECciCKmKtZTekKCUCAwEAAaNjMGEwDgYD
    VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFDwRpmIKYZvr
    lKqROus2Ae6gSKkDMB8GA1UdIwQYMBaAFDwRpmIKYZvrlKqROus2Ae6gSKkDMA0G
    CSqGSIb3DQEBCwUAA4IBgQA/LX15Qb7v/og06XB27TPl9StGBiewrb0WdHEz9H16
    eN926TwxWKUr6QcbGg6UbNfLUfMC3VicCDMTQCSNhBTUXm+4pKcJsTyM9/Sk/e4U
    5+l3FTgxXs+3mEoYJy16QlkU1XDr1q6Myo9Kc38d1yUW9OPxBV4Ur3+12uk5ElSC
    jZu7l+ox2FLds1TmYBhRR/2Jdbm5aoamh4FVpkmDgGedjERREymvnOIMkhWyUfWE
    L8Sxa2d8427cBieiEP4foLgjWKr2+diCDrBymU/pz/ZMRRpvUc2uFV005/vmDedK
    xQACQ8ZWBYWzNCV4C0Y5AS1PETxbocZ09Yw6K1XyVveEp8aQ/ROMkAUOObhMD45W
    GZNwewGU/V7kclDgMwq6R1VXr5R7NtK9V96vi6ZaujoJKvF1PFpZ/IHWcfFkpVoy
    Fu8L5PIkg4weBW+87kp+CCseEXPUplpqQCAnmVJdvilK6vgKc7T+vzbET8LNw7NX
    mHOVA3CR2w+yUhN4uiCI1aY=
    -----END CERTIFICATE-----

  # The url/ip of a proxy for kapp controller to use when making network
  # requests (optional)
  httpProxy: proxy-svc.proxy-server.svc.cluster.local:80

  # The url/ip of a tls capable proxy for kapp controller to use when
  # making network requests (optional)
  httpsProxy: ""

  # A comma delimited list of domain names which kapp controller should
  # bypass the proxy for when making requests (optional)
  noProxy: "github.com,docker.io"

  # A comma delimited list of domain names for which kapp controller, when
  # fetching images or imgpkgBundles, will skip TLS verification. (optional)
  dangerousSkipTLSVerify: "private-registry.com,insecure-registry.com"

  # JSON encoded array of kapp deploy rawOptions that are applied to all App CRs.
  # App CR specified rawOptions take precedence over what's specified here.
  # Value is parsed via go's json.Unmarshal.
  # (optional; v0.37.0+)
  kappDeployRawOptions: "[\"--diff-changes=true\"]"

  # Time duration value used as a default for App CR's spec.syncPeriod
  # if one is not specified explicitly. Minimum is 30s.
  # Value is parsed via go's time.ParseDuration.
  # (optional; v0.41.0+)
  appDefaultSyncPeriod: "30s"

  # Time duration value to force a minimum for App CR's spec.syncPeriod.
  # If this value is greater than explicitly specified syncPeriod,
  # this value value will be used instead. Minimum is 30s.
  # Value is parsed via go's time.ParseDuration.
  # (optional; v0.41.0+)
  appMinimumSyncPeriod: "30s"

  # Time duration value used as a default for App CR's spec.syncPeriod 
  # created via PackageInstall
  # if one is not specified explicitly. Minimum is 30s.
  # Value is parsed via go's time.ParseDuration.
  # (optional; v0.47.0+)
  packageInstallDefaultSyncPeriod: "10m"
```

## Config Shorthands

kapp-controller v0.30.0+ supports a shorthand for easily adding the `KUBERNETES_SERVICE_HOST` 
environment variable to kapp-controller's `noProxy` controller config property. This can help 
when a Kubernetes cluster is configured with a proxy and the kapp-controller-config is created 
with the http and https proxy URL. In this case, kapp-controller fails to communicate with the 
Kubernetes API server.

To make this configuration simpler, the `noProxy` property will interpret `KAPPCTRL_KUBERNETES_SERVICE_HOST` 
as the value of `KUBERNETES_SERVICE_HOST` (typically 10.96.9.1) environment variable in the kapp-controller pod.

```yaml
noProxy: "github.com,docker.io,KAPPCTRL_KUBERNETES_SERVICE_HOST"
```
