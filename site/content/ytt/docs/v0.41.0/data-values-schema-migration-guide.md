---

title: Schema Migration Guide
toc: "true"
---

Schema documents provide a way to declare Data Values with their types, and default values. Without Schema, validating the presence of Data Values requires additional `ytt` configuration containing Starlark assertions.

- Learn more about [writing Schema](how-to-write-schema.md)
- Read the detailed [Data Vaues Schema Reference](lang-ref-ytt-schema.md)

## How do I, a configuration author, migrate my `ytt` library to use Schemas?

To make use of the Schema feature, your `ytt` invocation must first contain files using the [Data Values feature](ytt-data-values.md). Migrating to Schemas involves converting your Data Values files into a Schema file.

### Single Data Values file

Starting with a single Data Values file, `values.yml`:
```yaml
#@data/values
---
key1: myVal
key2: 8080
```

Convert this Data Values file into Schema by changing the top level annotation in the document to say `#@data/values-schema`, and (optional) rename `values.yml` to `values-schema.yml`:
```yaml
#@data/values-schema
---
key1: myVal
key2: 8080
```
Now simply include this Schema file in your `ytt` invocation to receive the benefits of `ytt` Schemas.


**Note: If your Data Values file contains arrays (ie. `["example"]`, `- example`), be sure to [provide default values for arrays](#how-do-i-provide-default-values-for-an-array).**

### Multiple Data Values files
Sometimes, it makes sense to [split Data Values into multiple files](ytt-data-values.md#splitting-data-values-overlays-into-multiple-files).
If this is your situation, there are a few things to note.

Given a `ytt` configuration with two Data Values files:
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
You can convert each Data Values document into its own Schema document by [following the steps to convert a single Data Values file](#single-data-values-file).

[Multiple Schemas combine exactly like Data Values, via overlays](lang-ref-ytt-schema.md#multiple-schema-documents): 
the first Schema establishes the base set of "data value" declarations, and subsequent Schema files are overlays on top of that base.

`values-1-schema.yml`:
```yaml
#@data/values-schema
---
key1: myVal
key2: 8080
```

`values-2-schema.yml`:
```yaml
#@data/values-schema
---
key2: 8088
#@overlay/match missing_ok=True
key3:
  host: registry.dev.io
  port: 8080
```

Now just include these Schema files in your `ytt` invocation instead of the Data Values files.

### Multiple Data Values files + Private Libraries
If your configuration depends on a ytt library — outlined in the [library module docs](lang-ref-ytt-library.md) — there are a few points to note.

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
Using the same `values-1.yml` and `values-2.yml` files from the [multiple Data Values files Schema migration example above](#multiple-data-values-files).

Migrating to Schema happens one library at a time. Let's start with the root library, which includes everything at and below the file system level where the `ytt` invocation was called, not including the `_ytt_lib` folder:
```bash
.
└── config
    ├── config.yml
    ├── values-1.yml
    └── values-2.yml
```
As seen in the [previous example](#multiple-data-values-files), migrating this library to Schemas simply involves converting each `values-1.yml` and `values-2.yml`into a Schema file.

Now we have migrated the root library to use Schemas, and the `ytt` invocation will succeed as the same as before. Each library can independently opt-in to using Schemas. 
```bash
$ tree .
.
└── config
    ├── config.yml 
    ├── values-1-schema.yml
    ├── values-2-schema.yml
    └── _ytt_lib
        └── lib
            ├── service.yml
            └── values.yml
```
Migrating a private library to use Schemas involves the same process as the root library. You can narrow the context to just the children of the `_ytt_lib` directory:
```bash
└── _ytt_lib
    └── lib
        ├── service.yml
        └── values.yml
```
Now simply follow the steps in either of the previous examples to migrate the private library to use Schemas.

---

## How do I provide default values for an array?
Arrays in Schemas are [handled differently](lang-ref-ytt-schema.md#defaults-for-arrays) than other types:
exactly one element is specified in the array, and that value is _only_ used to infer the type of that array's elements —
the default value, by default, is an empty list (i.e. `[]`).

The example below shows how to define an array in a Schema and then provide default values via the `@schema/default` annotation.

`values-schema.yml`:
```yaml
#@ def default_conns():
- host: registry.dev.io
  port: 8080
  transport: tcp
#@ end

#@data/values-schema
---
#@schema/default default_conns()
key: 
- host: ""
  port: 0
  transport: ""
  insecure_disable_tls_validation: false
```

Given that schema, if a template file were to use the `key` data value:

```yaml
key: #@ data.values.key
```

this would output

```yaml
key:
- host: registry.dev.io
  port: 8080
  transport: tcp
  insecure_disable_tls_validation: false
```


## How do I mark a section of Data Values as "optional"?
Sometimes your configuration includes a section of Data Values that are not typically used or in some way optional.

If this the case, consider the guidance in [Writing Schema: Marking a Data Value as Optional](how-to-write-schema.md#marking-a-data-value-as-optional), use the 
[@schema/nullalble](lang-ref-ytt-schema.md#schemanullable) annotation to default such a section to `null`.

## How do I mark a Data Value as containing any kind of YAML?
For those looking to relax the typing that Schema applies to Data Values, the [@schema/type any=True](lang-ref-ytt-schema.md#schematype) annotation 
can be used to override the inferred typing on the node it annotates and its children.

Situations like this are covered in detail in [Writing Schema: Specific Use-Cases](how-to-write-schema.md#specific-use-cases)
