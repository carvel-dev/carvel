---

title: Using Data Values
---

## Overview

A Configuration Author introduces variables in `ytt` (i.e. to externalize configuration values) by:
1. declaring them as "Data Values" by naming it in a schema file and then,
2. referencing them in templates.

Configuration Consumers then set values for those variables in any combination of:
- one or more of the `--data-value...` flag(s) and/or
- Data Values Overlay(s) through the `--file` flag

This guide illustrates how to declare and configure data values.

_(for a higher-level overview of `ytt`, see [How it works](how-it-works.md).)_

### Declaring Data Values

In `ytt`, before a Data Value is used, it is declared. This is typically done in a schema file.

For example:

`schema.yml`
```yaml
#@data/values-schema
---
name: monitor
ingress:
  virtual_host_fqdn: "monitor.system.example"
  service_port: 80
  enable_tls: false
```

declares five Data Values:
- `name` contains a string; the default name is "monitor".
 - `ingress` is a map that contains three map items: `virtual_host_fqdn`,  `service_port`, and `enable_tls`.
- `ingress.virtual_host_fqdn` is a string; by default, the fully-qualified host name is the value given.
- `ingress.service_port` is an integer; by default, the service is listening on the standard HTTP port.
- `ingress.enable_tls` is a boolean; by default, transport layer security is off.

_(see the [How To Write Schema](how-to-write-schema.md) guide, for details.)_


### Referencing Data Values

Those Data Values can then be referred to in template(s):

`config.yml`
```yaml
#@ load("@ytt:data", "data")
---
name: #@ data.values.name
spec:
  virtualhost: #@ data.values.ingress.virtual_host_fqdn
  services:
  - port: #@ data.values.ingress.service_port
  #@ if/end data.values.ingress.enable_tls:
  - port: 443
```
where:
- `load("@ytt:data", "data")` imports the the `data` struct from the `@ytt:data` module
- `data.values` contains all of the declared data values
- `#@ if/end` only includes the annotated array item if the data value `ingress.enable_tls` is true.

Using the defaults given in the schema, `ytt` produces:
```console
$ ytt -f schema.yml -f config.yml
name: monitor
spec:
  virtualhost: monitor.system.example
  services:
  - port: 80
```

_(For details on using the Data module, refer to [`@ytt:data`](lang-ref-ytt.md#data).)_

### Configuring Data Values

Those Data Values can be configured by a Consumer:

This is done, typically, via a Data Values File:

`values.yml`
```yaml
---
name: observer
ingress:
  virtual_host_fqdn: "observer.system.example"
  enable_tls: true
```

which is a plain YAML file (i.e. _cannot_ contain any `ytt` templating). This file is specified through the `--data-values-file` flag.

Using the example files from above, `ytt` produces this output:

```console
$ ytt -f schema.yml -f config.yml --data-values-file values.yml
name: observer
spec:
  virtualhost: observer.system.example
  services:
  - port: 80
  - port: 443
```

Supplied Data Values are automatically checked against the schema. If any value is of the wrong type, `ytt` reports the discrepancies and stops processing.

_(For details on how to configure Data Values, consult the [Data Values](ytt-data-values.md) reference.)_


## Resources

Documentation:
- [How To Write Schema](how-to-write-schema.md) guide — step-by-step writing schema in `ytt`.
- [Data Values Reference](ytt-data-values.md) — details of how Data Values are specified in all scenarios.
- [Data Values Schema Reference](lang-ref-ytt-schema.md) — the anatomy of a `ytt` Schema file all elements within.
- [Schema Migration Guide](data-values-schema-migration-guide.md) — migrating existing `ytt` code from pre-Schema versions.

Examples:
- Declaring and using Data Values in schema: \
  https://github.com/carvel-dev/ytt/tree/develop/examples/schema
- Setting a value for an _array_ in schema: \
  https://github.com/carvel-dev/ytt/tree/develop/examples/schema-arrays
- Using most of the `--data-value...` flags:\
  https://github.com/carvel-dev/ytt/tree/develop/examples/data-values/
- Marking a data value as "required":\
  https://github.com/carvel-dev/ytt/tree/develop/examples/data-values-required/
- Maintaining per-environment data value overrides:\
  https://github.com/carvel-dev/ytt/tree/develop/examples/data-values-multiple-envs
- Wrapping an upstream set of templates to expose a simplified set of data values:\
  https://github.com/carvel-dev/ytt/tree/develop/examples/data-values-wrap-library
- Using a directory full of YAML files for data values input:\
  https://github.com/carvel-dev/ytt/tree/develop/examples/data-values-directory

Blog Articles:
- [Parameterizing Project Configuration with ytt](https://carvel.dev/blog/parameterizing-project-config-with-ytt/), by Garrett Cheadle
- [Deploying to multiple environments with ytt and kapp](https://carvel.dev/blog/multi-env-deployment-ytt-kapp/), by Yash Sethiya

