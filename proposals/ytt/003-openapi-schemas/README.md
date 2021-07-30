# Export OpenAPI Schema

- Status: **Scoping** | Pre-Alpha | In Alpha | In Beta | GA | Rejected
- Originating Issue: [ytt#103](https://github.com/vmware-tanzu/carvel-ytt/issues/103)

# Problem Statement
Configuration Authors want to be able to generate documentation for configuration inputs (for example, Data Values Schema, and Data Values) for their users. Additionally, Configuration Consumers want to be able to validate their configuration inputs by other tools (for example, IDE's and OpenAPI Schema validators). 

# Proposal
Implement a flag to export an [OpenAPI Schema](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md) yaml document generated from a [Data Values schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) file, and an optional Data Values file. When invoking ytt with configuration inputs and the flag `--schema-inspect-openapi`, the result is the OpenAPI formatted document only. 

This flag will behave similar to the `--data-values-inspect` flag, which excludes any templates in the output.

## Examples:
### Scenario 1: Data Values Schema file only
`ytt -f schema.yml --schema-inspect-openapi` will generate an OpenAPI Schema document using the values from the schema.yml file.

### Scenario 2: Data Values Schema and Data Values
`ytt -f schema.yml -f values.yml --schema-inspect-openapi` will generate an OpenAPI Schema document using the merged values of both the schema.yml and the values.yml file.

Note: Using the merged result of both files allows the generated OpenAPI Schema to have a default value for array items, since Data Values Schema files do not yet support default values for arrays. Additionally, it allows the OpenAPI Schema to document the merged result of Data Values Schema and Data Values that will ultimately be used as configuration input during templating.

### Scenario 3: Data Values file only
`ytt -f values.yml --schema-inspect-openapi` will result in a warning suggesting that a Data Values Schema file be provided. 

The reason for waiting to support Data Values files only is so that the OpenAPI document can have the additional information of default values and descriptions only available in Data Values Schema files. If this functionality comes with no additional work, we should reevaluate this decision.

# Specification
## Glossary
* OpenAPI Schema: A document that follows this [spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
* Collection: a yaml map or array
* Configuration inputs: a ytt Schema file and a Data Values file
* [Data Value Schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) A ytt document that declares default values and type information for parameterized values.
* [Data Value](https://carvel.dev/ytt/docs/latest/ytt-data-values/) A ytt document that overrides defaults declared in a Data Values Schema.


## Generated Openapi Document Spec:

### Root Document fields:
```yaml
openapi: 3.1.0 # Version of the openapi spec
info:
  version: 1.0.0 # Version of this document
  title: Openapi schema generated from ytt schema # Title of this document
components: # Required field that holds 'schemas object'
  ...
```
All openapi schemas generated will be prefixed by the above.

### Openapi Map Example:
#### Ytt schema:
```yaml
#@data/values-schema
---
load_balancer:
  enabled: true
  static_ip: ""
```
#### openapi schema:
```yaml
...
components:
  schemas:
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

## References:
- [document spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#openapi-object)
- [info object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#info-object)
- [schema object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#schemaObject)