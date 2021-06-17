---
title: Schema Migration Guide
toc: "true"
---

Schema documents provide a way to declare data values with their types, and default values. Without schemas, validating the presence of data values requires additional `ytt` configuration containing starlark assertions.

[Learn more about using schema here.](ytt-schema.md)\
[Read the detailed schema module here.](lang-ref-ytt-schema.md)


## How do I, a configuration author, migrate my `ytt` library to use schemas?

To make use of the schema feature, your `ytt` invocation must first contain files using the [data values feature](ytt-data-values.md). Migrating to schemas involves converting your data values files into a schema file.

### Single data values file

Starting with a single data values file, `values.yml`:
```yaml
#@data/values
---
key1: myVal
key2: 8080
```

Convert this data values file into schema by changing the top level annotation in the document to say `#@data/values-schema`, and (optional) rename `values.yml` to `values-schema.yml`:
```yaml
#@data/values-schema
---
key1: myVal
key2: 8080
```
Now simply include this schema file in your `ytt` invocation to receive the benefits of `ytt` schemas.


**Note: If your data values file contains arrays (ie. `["example"]`, `- example`), be sure to [provide default values for arrays](#how-do-i-provide-default-values-for-an-array).**

### Multiple data values files
For this case, be sure that you are [using multiple data values files](ytt-data-values.md#splitting-data-values-into-multiple-files). 

Given a `ytt` configuration with two data values files:
```bash
$ tree .
.
├── config.yml
├── values-1.yml
└── values-2.yml
```

`values-1.yml`:
```yaml
#@data/values
---
key1: myVal
key2: 8080
```

`values-2.yml`:
```yaml
#@data/values
---
key2: 8088
#@overlay/match missing_ok=True
key3:
  host: registry.dev.io
  port: 8080
```
The first step is to combine these two sets of data values into a single set of data values (a union set of all top level keys from the data values files).
`ytt` can do this for you by providing the`--data-values-inspect` flag to your usual `ytt` command:
```bash
$ `ytt -f . --data-values-inspect
key1: myVal
key2: 8088
key3:
  host: registry.dev.io
  port: 8080
```
You can now copy this output into a yaml file and make it a schema by adding the `#@data/values-schema` annotation to the top of a new document.

`values-schema.yml`:
```yaml
#@data/values-schema
---
key1: myVal
key2: 8088
key3:
  host: registry.dev.io
  port: 8080
```

Now just include the `values-schema.yml` file in your `ytt` invocation instead of the multiple data values files.

### Multiple data values files + Private libraries
In this scenario, we expect your configuration to depend on a ytt library; outlined in the [library module docs](lang-ref-ytt-library.md).

```bash
$ tree .
.
└── config
    ├── config.yml 
    ├── values-1.yml
    ├── values-2.yml
    └── _ytt_lib
        └── lib
            ├── service.yml
            └── values.yml
```
`config.yml`:
```yaml
#@ load("@ytt:data", "data")
#@ load("@ytt:library", "library")
#@ load("@ytt:template", "template")

#@ lib = library.get("lib").with_data_values(data.values)
--- #@ template.replace(lib.eval())
```
Using the same `values-1.yml` and `values-2.yml` files from the [multiple data values files schema migration example above](#multiple-data-values-files).
Migrating to schema happens one library at a time. Let's start with the root library, which includes everything at and below the file system level where the `ytt` invocation was called, not including the `_ytt_lib` folder:
```bash
.
└── config
    ├── config.yml
    ├── values-1.yml
    └── values-2.yml
```
As seen in the [previous example](#multiple-data-values-files), `values-1.yml` and `values-2.yml` can be combined and replaced with a single schema file:
`values-schema.yml`:
```yaml
#@data/values-schema
---
key1: myVal
key2: 8088
key3:
  host: registry.dev.io
  port: 8080
```
Now we have migrated the root library to use schemas, and the `ytt` invocation will succeed as the same as before, but the private library, "lib" is not yet migrated to schema. 
```bash
$ tree .
.
└── config
    ├── config.yml 
    ├── values-schema.yml
    └── _ytt_lib
        └── lib
            ├── service.yml
            └── values.yml
```
Migrating a private library to use schemas involves the same process as the root library. You can narrow the context to just the children of the `_ytt_lib` directory:
```bash
└── _ytt_lib
    └── lib
        ├── service.yml
        └── values.yml
```
Now simply follow the steps in either of the previous examples to migrate the private library to use schemas.

## How do I provide default values for an array?
Arrays in schemas have [special behavior](lang-ref-ytt-schema.md#inferring-defaults-for-arrays), their default value is empty, but their inferred type is from the value in the schema document. 
Arrays must have one and only one item, which provides the inferred type of that data value. The example below shows how to define an array in a schema and them provide default values via a data values file.

`values-schema.yml`:
```yaml
#@data/values-schema
---
key: 
- host: ""
  port: 0
  transport: ""
  insecure_disable_tls_validation: false
```

`values.yml`:
```yaml
#@data/values
---
key:
- host: registry.dev.io
  port: 8080
  transport: tcp
```
Providing these files along with a template file containing `key: #@ data.values.key` will produce:
```yaml
key:
- host: registry.dev.io
  port: 8080
  transport: tcp
  insecure_disable_tls_validation: false
```


## How do I mark a section of Data Values as "optional"?
The [@schema/nullalble](lang-ref-ytt-schema.md#schemanullable) annotation can be used to override the defaults of the node it annotates.

Use this annotation on a node if `null` is valid input, or you want the default value for that data value to be `null`. (This annotation cannot be use on arrays.)

## How do I mark a Data Value as containing any kind of YAML? (any)
The [@schema/type any=True](lang-ref-ytt-schema.md#schematype) annotation 
that can be used to override the inferred typing and defaults of the node it annotates.

If the constraints given by the schema on a data value need to be relaxed, do so by placing `@schema/type any=True` on the node; any value of any type (as long as valid yaml) can be provided as the value of this node.
