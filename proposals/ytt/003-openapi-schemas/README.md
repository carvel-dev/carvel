# Generate OpenAPI Schema

- Status: **Scoping** | Pre-Alpha | In Alpha | In Beta | GA | Rejected
- Originating Issue: [ytt#103](https://github.com/vmware-tanzu/carvel-ytt/issues/103)

# Problem Statement
Configuration Authors want to be able to generate documentation for configuration inputs (for example, Data Values Schema, and Data Values) for their users. Additionally, Configuration Consumers want to be able to validate their configuration inputs by other tools (for example, IDE's and OpenAPI Schema validators). 

# Proposal
Implement the flag `--data-values-schema-inspect -o openapi` to create an [OpenAPI Document](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object) from a [Data Values schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) file. When invoking ytt with this flag and a Data Values Schema file, a yaml OpenAPI document that has [ headers](#openapi-document-with-metadata) such as version, and a [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schema-object) is output. 

The following additional flags may be implemented.

The `--data-values-inspect -o openapi` flag creates an OpenAPI Document from a Data Values Schema, and a Data Values file. The flag `--data-values-inspect` currently exists and outputs the values that result from merging Data Values Schema and Data Values together. The addition of `-o openapi` would use the merged values of Data Values Schema and Data Values to output an OpenAPI Document.

The  `--data-values-schema-inspect` flag creates a ytt schema with annotations (_not in OpenAPI format_) from a Data Values Schema file.

The `--data-values-schema-inspect -o openapi-schema` flag creates an OpenAPI [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schema-object) only (without any headers) from a Data Values Schema file.

All of these flags will behave similar to the `--data-values-inspect` flag, which excludes any templates in the output.

Here is a list of the similar current and proposed flags
```bash
# current flags
ytt --files-inspect                 # prints involved files
ytt --data-values-inspect           # prints values files
ytt --data-values-inspect -ojson    # prints values as json

# New flags
ytt --data-values-schema-inspect -o openapi     # prints data values schema files as an OpenAPI Document

# Additional New flags
ytt --data-values-inspect -o openapi    # prints values files as OpenAPI Document
ytt --data-values-schema-inspect    # prints ytt schema (as ytt schema with annotations)
ytt --data-values-schema-inspect -o openapi-schema    # prints data values schema files as an OpenAPI Schema
```

## Examples:
### Scenario 1: Data Values Schema file only
`ytt -f schema.yml --data-values-schema-inspect -o openapi` will generate an OpenAPI Schema document using the Data Values Schema `schema.yml` file.

### Scenario 2: Data Values Schema and Data Values (AKA Data Values Overlays)
`ytt -f schema.yml -f values.yml --data-values-schema-inspect -o openapi` will generate an OpenAPI Schema document using **only** the Data Values Schema `schema.yml`, and will ignore the Data Values file `values.yml`.

**Note**: Restricting this flag to only use Data Values Schema files results in the values from Data Values Overlays not appearing in the OpenAPI Document, despite that they may ultimately be used as Data Values during templating. However, once Data Values Schema files support default values for Arrays, Configuration Authors will be able to supply all their values as Data Values Schema, and the need for using Data Values Overlays can be replaced with using Data Value Schema overlays, thus avoiding this issue.

### Scenario 3: Data Values file only
`ytt -f values.yml --data-values-schema-inspect -o openapi` will result in a warning suggesting that a Data Values Schema file be provided.

`ytt -f values.yml --data-values-inspect -o openapi` will generate an OpenAPI Schema document using both the Data Values Schema `schema.yml`, and the Data Values file `values.yml`

## Use Cases
### Inserting an OpenAPI Schema into a kapp-controller Package CR
A kapp-controller [Package](/kapp-controller/docs/latest/packaging/#package-1) has a `valuesSchema` key where the OpenAPI Schema is placed to provide documentation on what data values may be used with ytt templated configuration. Currently, this is a manual process to create the OpenAPI Schema. This is the recommended workflow:
1. Create an OpenAPI Document from a Data Values Schema file: `ytt -f schema.yml --data-values-schema-inspect -o openapi`.
```yaml
#! openapi.yml
openapi: 3.1.0
info:
  version: 1.0.0
  title: Openapi schema generated from ytt schema
components:
  schemas:
    type: object
    properties:
      namespace:
        type: string
        default: fluent-bit
```
2. Insert the OpenAPI Schema Object into a Package via `ytt -f package.yml --data-value-file openapi=openapi.yml`
```yaml
#@ load("@ytt:data", "data")
#@ load("@ytt:yaml", "yaml")
#! package.yml
...
kind: Package
spec:
  valuesSchema:
    openAPIv3:  #@ yaml.decode(data.values.openapi)["components"]["schemas"]
```
Note: the data value is named in the command by `openapi=openapi.yml` to avoid conflicts, and since the file is read as a string the `yaml.decode()` is necessary to prevent it from being a multiline string.

# Specification
## Generated Openapi Document Spec:

### OpenAPI Document with headers
Invoking ytt with `ytt -f . --data-values-schema-inspect -o openapi` results in a complete OpenAPI Document that includes both the Schema Object and the headers shown the yaml below. The headers allow the Document to be compliant with the OpenAPI spec and to include metadata like OpenAPI version.
#### Root Document fields:
```yaml
openapi: 3.1.0 # Version of the openapi spec
info:
  version: 1.0.0 # Version of this document
  title: Openapi Schema generated from ytt schema # Title of this document
components: # Required field that holds 'schemas object'
  schemas:
   ...
```

#### OpenAPI Map Example:
##### Ytt Schema:
```yaml
#@data/values-schema
---
load_balancer:
  enabled: true
  static_ip: ""
```
##### OpenAPI Document:
```yaml
openapi: 3.1.0
info:
  version: 1.0.0
  title: Openapi schema generated from ytt schema
components: 
  schemas:
    type: object # `object` is always the type for a collection
    properties: # `properties` holds the items in the collection
      load_balancer:
        type: object
        properties:
          enabled:
            type: boolean
          static_ip:
            type: string
        required:
          - enabled
          - static_ip
        additionalProperties: false # disallows any other items than those listed for this collection
    required:
      - load_balancer
    additionalProperties: false
```
### OpenAPI `Schemas` object
Some users (e.g. kapp-controller) only need the Schemas object and not an entire OpenAPI document. To make easier substitution of the output of this flag into an existing document `ytt -f . --data-values-schema-inspect -o openapi-schema` outputs only the Schema Object (`components.schemas`) section of an OpenAPI Document.

## Glossary
* OpenAPI Schema: A document that follows this [spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
* Collection: a yaml map or array
* Configuration inputs: a ytt Schema file and a Data Values file
* [Data Value Schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) A ytt document that declares default values and type information for parameterized values.
* [Data Value](https://carvel.dev/ytt/docs/latest/ytt-data-values/) A ytt document that overrides defaults declared in a Data Values Schema.
* [Schemas Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schema-object): The `components.schemas` section of an OpenAPI Document that defines the input and output data types.
* Data Values Overlay: a Data Values document preceded by either a Data Values or Data Values Schema file.

## References:
- [document spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
- [info object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#info-object)
- [schema object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schemaObject)