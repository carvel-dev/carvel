---
title: Using Schema
---

## Overview

`ytt` schemas are currently in the **experimental** phase. To use schema features, include `--enable-experiment-schema`.

Configuration Authors use Schema to declare data values; specifying the type and default value for each.

Using a schema guarantees to templates that all data values exist and are of the correct type. This alleviates templates from doing existence and type checks themselves.

Common use cases:

1. Set default values
1. Provide visibility to valid values that could be updated by the consumer 
1. Provide visibility to valid types and YAML structure that could be updated by the consumer

Consider this simple example schema provided by the _configuration author_:

> `schema.yml`
> ```yaml
> #@schema/match data_values=True
> ---
> load_balancer:
>   enabled: true
>   external_ip: ""
> ```
A Configuration _Consumer_ may customize these by providing their own data values. If supplied, `load_balancer.enabled` must be a `bool`, and `load_balancer.external_ip` must be a `string`. No additional data values can be included.

> `values.yml`
> ```yaml
> #@data/values
> ---
> load_balancer:
>   external_ip: 172.120.12.232
> ```

Then paired with a template
> `config.yml`
> ```yaml
> #@load("ytt:data", "data")
> ---
> service: #@ data.values.load_balancer
> ```
> 
And processed by `ytt`
```console
$ ytt -f schema.yml -f values.yml -f config.yml --enable-experiment-schema
```

The result includes the default `load_balancer.enabled` from the schema, and the `load_balancer.external_ip` from the data values file.
```yaml
service:
  load_balancer:
    enabled: true
    external_ip: 172.120.12.232
```
  
Check out how default values work [here](lang-ref-ytt-schema.md#inferring-default-values).
