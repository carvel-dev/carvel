# Generate OpenAPI Schema

- Status: **Scoping** | Pre-Alpha | In Alpha | In Beta | GA | Rejected
- Originating Issue: [ytt#103](https://github.com/vmware-tanzu/carvel-ytt/issues/103)

# Problem Statement
Configuration Authors want to be able to generate documentation for configuration inputs (for example, Data Values Schema, and Data Values) for their users. Additionally, Configuration Consumers want to be able to validate their configuration inputs by other tools (for example, IDE's and OpenAPI Schema validators). 

# Proposal
Implement a flag to create an [OpenAPI Schema](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md) yaml document generated from a [Data Values schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) file, and an optional Data Values file. When invoking ytt with configuration inputs and the flag `--data-values-schema-inspect -o openapi`, the result is the OpenAPI formatted Schema object only. 
In addition, the `--data-values-schema-inspect -o openapi-full` flag may be used to include _both_ the [OpenAPI headers](#openapi-document-with-metadata) and the [Schema object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schema-object).
Lastly, the `--data-values-schema-inspect` flag will output ytt schema with annotations (_not in OpenAPI format_).

This flag will behave similar to the `--data-values-inspect` flag, which excludes any templates in the output.

Here is a list of the similar current and proposed flags
```bash
# current flags
ytt --files-inspect                 # prints involved files
ytt --data-values-inspect           # prints values files
ytt --data-values-inspect -ojson    # prints values as json

# New flags
ytt --data-values-schema-inspect    # prints ytt schema (as ytt schema with annotations)
ytt --data-values-schema-inspect -o openapi     # prints data values schema in openapi format
ytt --data-values-schema-inspect -o openapi-full     # prints data values schema in openapi format with headers
```

## Examples:
### Scenario 1: Data Values Schema file only
`ytt -f schema.yml --data-values-schema-inspect -o openapi` will generate an OpenAPI Schema document using the values from the schema.yml file.

### Scenario 2: Data Values Schema and Data Values
`ytt -f schema.yml -f values.yml --data-values-schema-inspect -o openapi` will generate an OpenAPI Schema document using the merged values of both the schema.yml and the values.yml file.

Note: Using the merged result of both files allows the generated OpenAPI Schema to have a default value for array items, since Data Values Schema files do not yet support default values for arrays. Additionally, it allows the OpenAPI Schema to document the merged result of Data Values Schema and Data Values that will ultimately be used as configuration input during templating.

### Scenario 3: Data Values file only
`ytt -f values.yml --data-values-schema-inspect -o openapi` will result in a warning suggesting that a Data Values Schema file be provided. 

The reason for waiting to support Data Values files only is so that the OpenAPI document can have the additional information of default values and descriptions only available in Data Values Schema files. If this functionality comes with no additional work, we should reevaluate this decision.

## Use Cases
### Inserting an OpenAPI Schema into a kapp-controller Package CR
A kapp-controller [Package](/kapp-controller/docs/latest/packaging/#package-1) has a `valuesSchema` key where the OpenAPI Schema is placed to provide documentation on what data values may be used with ytt templated configuration. Currently, this is a manual process to create the OpenAPI Schema. This is the recommended workflow:
1. Create an OpenAPI Schema from a Data Values Schema file
```
#! openapi.yml
namespace:
  type: string
  default: fluent-bit
```
2. Insert the OpenAPI Schema into a PackageCR via `ytt -f package.yml --data-value-file openapiSchema=openapi.yml`
```
#@ load("@ytt:data", "data")
#@ load("@ytt:yaml", "yaml")
#! package.yml
...
kind: Package
spec:
valuesSchema:
openAPIv3: #@ yaml.decode(data.values.openapiSchema)
```
Note: the data value is named in the command by `openapiSchema=openapi.yml`, and since the file is read as a string the `yaml.decode()` is necessary to prevent it from being a multiline string.

# Specification
## Generated Openapi Document Spec:
### OpenAPI `Schemas` object
Some users (e.g. kapp-controller) only need the Schemas object and not an entire OpenAPI document. To make easier substitution of the output of this flag into an existing document `ytt -f . --data-values-inspect -o openapi` outputs only the Schema object section of an OpenAPI Document.

#### Openapi Map Example:
##### Ytt schema:
```yaml
#@data/values-schema
---
load_balancer:
  enabled: true
  static_ip: ""
```
##### openapi schema:
```yaml
load_balancer:
  type: object # `object` is always the type for a collection
  properties:  # `properties` holds the items in the collection
    enabled: 
      type: boolean
    static_ip: 
      type: string
  required:
  - enabled
  - static_ip
  additionalProperties: false # disallows any other items than those listed for this collection
```

### OpenAPI Document with headers 
Invoking ytt with `ytt -f . --data-values-inspect -o openapi-full` results in a complete OpenAPI document that includes both the Schema Object and the headers from the yaml below. 

The benefit of this flag would be to have a OpenAPI spec compliant document if needed, and include metadata like version. Additionally, using this flag simplifies the [kapp-controller workflow](#use-cases) slightly since would not need to `struct.encode()` the data.

#### Root Document fields:
```yaml
openapi: 3.1.0 # Version of the openapi spec
info:
  version: 1.0.0 # Version of this document
  title: Openapi schema generated from ytt schema # Title of this document
components: # Required field that holds 'schemas object'
  schemas:
   ...
```

## Glossary
* OpenAPI Schema: A document that follows this [spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
* Collection: a yaml map or array
* Configuration inputs: a ytt Schema file and a Data Values file
* [Data Value Schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) A ytt document that declares default values and type information for parameterized values.
* [Data Value](https://carvel.dev/ytt/docs/latest/ytt-data-values/) A ytt document that overrides defaults declared in a Data Values Schema.
* [Schemas Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schema-object): The `components.schemas` section of an OpenAPI Document that defines the input and output data types.

## References:
- [document spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
- [info object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#info-object)
- [schema object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schemaObject)