---
title: Using Data Values
---

## Overview

The standard way to externalize configuration values is to:
1. declare them as "Data Values" in a schema,
2. reference those values in templates, and
3. (optionally) configure them through Data Value inputs.

This guide shows how to do this.

_(For a high-level overview of `ytt`, see [How it works](how-it-works.md).)_


### Declaring Data Values

In `ytt`, before a Data Value can be used in a template, it must be declared. This is typically done in a schema file.

For example:

`schema.yml`
```yaml
#@data/values-schema
---
load_balancer:
  enabled: true
  external_ip: ""
```

declares three Data Values:
- `load_balancer` is a map that contains two map items: `enabled` and `external_ip`.
- `load_balancer.enabled` is a boolean; by default it is `true`.
- `load_balancer.external_ip` is a string; by default it is an empty string.

  
_(see the [How To Write Schema](how-to-write-schema.md) guide, for details.)_


### Referencing Data Values

Those Data Values can then be used in a template via the `@ytt:data` module.

`config.yml`
```yaml
#@load("ytt:data", "data")
---
service: #@ data.values.load_balancer
```

_(For details on using the Data module, refer to [`@ytt:data`](lang-ref-ytt.md#data).)_

### Configuring Data Values

Further, those Data Values can be customized by a Consumer by providing their own data values:

`values.yml`
```yaml
#@data/values
---
load_balancer:
  external_ip: 172.120.12.232
```

When Data Values are supplied, their values are checked against the schema to ensure they are of the right type and shape. If there are any errors, `ytt` stops processing and reports them.

_(For details on how to configure Data Values, consult the [Data Values](ytt-data-values.md) reference.)_

...

Using the example files from above, `ytt` produces this output:

```console
$ ytt -f schema.yml -f values.yml -f config.yml
service:
  load_balancer:
    enabled: true
    external_ip: 172.120.12.232
```

Note:
- `load_balancer.enabled` is the default as set in `schema.yml`
- `load_balancer.external_ip` is the configured value from `values.yml`

## Next Steps

More examples:
- simple and complete example of declaring and using Data Values through schema: \
  https://github.com/vmware-tanzu/carvel-ytt/tree/develop/examples/schema
- example declaring and configuring an array: \
  https://github.com/vmware-tanzu/carvel-ytt/tree/develop/examples/schema-arrays

Related documentation:
- [How To Write Schema](how-to-write-schema.md) guide
- [Data Values](ytt-data-values.md) reference
- [Data Values Schema Reference](lang-ref-ytt-schema.md)
- [Schema Migration Guide](data-values-schema-migration-guide.md)
