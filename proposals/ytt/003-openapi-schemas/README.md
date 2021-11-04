# Generate OpenAPI Schema

- Status: Scoping | **Pre-Alpha** | In Alpha | In Beta | GA | Rejected
- Originating Issue: [ytt#103](https://github.com/vmware-tanzu/carvel-ytt/issues/103)

# Problem Statement
Configuration Authors want to be able to generate documentation for configuration inputs (for example, Data Values Schema, and Data Values) for their users. Additionally, Configuration Consumers want to be able to validate their configuration inputs by other tools (for example, IDE's and OpenAPI Schema validators). 

# Proposal
Implement the flag `--data-values-schema-inspect -o openapi-v3` to create an [OpenAPI Document](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#openapi-object) from one or more [Data Values schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) files merged together. When invoking ytt with this flag and a Data Values Schema file, a yaml OpenAPI document that has [headers](#openapi-document-with-metadata) such as version, and a [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#schema-object) is output. 

The following additional flags may be implemented.

The `--data-values-inspect -o openapi-v3` flag creates an OpenAPI Document from a Data Values Schema, and a Data Values file. The flag `--data-values-inspect` currently exists and outputs the values that result from merging Data Values Schema and Data Values together. The addition of `-o openapi-v3` would use the merged values of Data Values Schema and Data Values to output an OpenAPI Document.

The  `--data-values-schema-inspect` flag creates a ytt schema with annotations (_not in OpenAPI format_) from a Data Values Schema file.

The `--data-values-schema-inspect -o openapi-v3-schema` flag creates an OpenAPI [Schema Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#schema-object) only (without any headers) from a Data Values Schema file.

All of these flags will behave similar to the `--data-values-inspect` flag, which excludes any templates in the output.

Here is a list of the similar current and proposed flags
```bash
# current flags
ytt --files-inspect                 # prints involved files
ytt --data-values-inspect           # prints values files
ytt --data-values-inspect -ojson    # prints values as json

# New flags
ytt --data-values-schema-inspect -o openapi-v3[,yaml]   # prints data values schema as an OpenAPI Document (in YAML format; this is the default)
ytt --data-values-schema-inspect -o openapi-v3,json     # prints data values schema as an OpenAPI Document (in JSON format)

# Additional New flags
ytt --data-values-inspect -o openapi-v3    # prints values files as OpenAPI Document
ytt --data-values-schema-inspect    # prints ytt schema (as ytt schema with annotations)
ytt --data-values-schema-inspect -o openapi-v3-schema    # prints data values schema files as an OpenAPI Schema
```

## Examples:
### Scenario 1: Data Values Schema file only
`ytt -f schema.yml --data-values-schema-inspect -o openapi-v3` will generate an OpenAPI Schema document using the Data Values Schema `schema.yml` file.

### Scenario 2: Data Values Schema and Data Values (AKA Data Values Overlays)
`ytt -f schema.yml -f values.yml --data-values-schema-inspect -o openapi-v3` will generate an OpenAPI Schema document using **only** the Data Values Schema `schema.yml`, and will ignore the Data Values file `values.yml`.

**Note**: Restricting this flag to only use Data Values Schema files results in the values from Data Values Overlays not appearing in the OpenAPI Document, despite that they may ultimately be used as Data Values during templating. However, once Data Values Schema files support default values for Arrays, Configuration Authors will be able to supply all their values as Data Values Schema, and the need for using Data Values Overlays can be replaced with using Data Value Schema overlays, thus avoiding this issue.

### Scenario 3: Data Values file only
`ytt -f values.yml --data-values-schema-inspect -o openapi-v3` will result in a warning suggesting that a Data Values Schema file be provided.

`ytt -f values.yml --data-values-inspect -o openapi-v3` will generate an OpenAPI Schema document using both the Data Values Schema `schema.yml`, and the Data Values file `values.yml`

## Use Cases
### Inserting an OpenAPI Schema into a kapp-controller Package CR
A kapp-controller [Package](/kapp-controller/docs/latest/packaging/#package-1) has a `valuesSchema` key where the OpenAPI Schema is placed to provide documentation on what data values may be used with ytt templated configuration. Currently, this is a manual process to create the OpenAPI Schema. This is the recommended workflow:
1. Create an OpenAPI Document from a Data Values Schema file: `ytt -f schema.yml --data-values-schema-inspect -o openapi-v3`.
```yaml
#! openapi.yml
openapi: 3.0.3
info:
  version: 1.0.0
  title: Openapi schema generated from ytt schema
paths: {}
components:
  schemas:
    dataValues:
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
    openAPIv3:  #@ yaml.decode(data.values.openapi)["components"]["schemas"]["dataValues"]
```
Note: the data value is named in the command by `openapi=openapi.yml` to avoid conflicts, and since the file is read as a string the `yaml.decode()` is necessary to prevent it from being a multiline string.

# Specification
## Generated Openapi Document Spec:

### OpenAPI Document with headers
Invoking ytt with `ytt -f . --data-values-schema-inspect -o openapi-v3` results in a complete OpenAPI Document that includes both the Schema Object and the headers shown the yaml below. The headers allow the Document to be compliant with the OpenAPI spec and to include metadata like OpenAPI version.
#### Root Document fields:
```yaml
openapi: 3.0.3 # Version of the openapi spec
info:
  version: 1.0.0 # Version of this document
  title: Openapi Schema generated from ytt schema # Title of this document
paths: {} # Required field that is not needed
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
openapi: 3.0.3
info:
  version: 1.0.0
  title: Openapi schema generated from ytt schema
paths: {}
components: 
  schemas:
    dataValues:
      type: object # `object` is always the type for a collection
      properties: # `properties` holds the items in the collection
        load_balancer:
          type: object
          properties:
            enabled:
              type: boolean
            static_ip:
              type: string
          additionalProperties: false # disallows any other items than those listed for this collection
      additionalProperties: false
```
### OpenAPI `Schemas` object
Some users (e.g. kapp-controller) only need the Schemas object and not an entire OpenAPI document. To make easier substitution of the output of this flag into an existing document `ytt -f . --data-values-schema-inspect -o openapi-v3-schema` outputs only the Schema Object (`components.schemas`) section of an OpenAPI Document.

## Implementation breakdown
### Phase 0 - Export OpenAPI Document from Data Values Schema
After this phase is complete the users would be able to:

Use`--data-values-schema-inspect -o openapi-v3` flag to export an OpenAPI Document. At this point no other flags will exist, and using `--data-values-schema-inspect` without `-o openapi` is disallowed.

**Note**: After this phase, we will gather data from users to determine the next highest priority, and the phases below may shift places.

### Phase 1 - Export OpenAPI Schema only from Data Values Schema
After this phase is complete the users would be able to:

Use`--data-values-schema-inspect -o openapi-v3-schema` to export an OpenAPI Schema. Again,`--data-values-schema-inspect` without `-o openapi` is disallowed.

### Phase 2 - Export a ytt Data Values Schema 
After this phase is complete the users would be able to:

Use`--data-values-schema-inspect` to export or inspect a Data Values Schema that includes ytt Schema annotations.


### Phase 3 - Export OpenAPI Document from Data Values Schema and Data Values
After this phase is complete the users would be able to:

Use `--data-values-inspect -o openapi-v3` to generate an OpenAPI Schema document using both Data Values Schema and Data Values files.

## Implementation Details
As part of the phase 0 of this work, the headers for an OpenAPI Doc will need to be created, and the Data Values Schema will be output in OpenAPI format. To be able to export all the fields needed in an OpenAPI Doc, a few ytt Schema annotations will need to be implemented.

The `#@schema/default` annotation will need to be implemented in order to have default values for arrays in a Data Value Schema. Implementing this annotation allows all elements of a Schema to be supplied by Data Values Schema files, since phase 0 flag only uses Data Values Schema files, this is necessary for full compatibility.

Implement the export of an OpenAPI Doc that has the `type` and `default` keys that will provide information for scalar types and collection types from a Data Values schema.

Implement the export of an OpenAPI Doc that represents the equivalent of ytt's `#@schema/nullable` and `#@schema/type any=True` annotations.

At this point, users can start testing and using this incomplete feature.

The `#@schema/desc` annotation will need to be implemented to provide the `description` key that explains what a key in a schema is.

The `#@schema/example` annotation will need to be implemented to provide an `example` key for a key in the schema.

## Glossary
* OpenAPI Schema: A document that follows this [spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#openapi-object)
* Collection: a yaml map or array
* Configuration inputs: a ytt Schema file and a Data Values file
* [Data Value Schema](https://carvel.dev/ytt/docs/latest/lang-ref-ytt-schema/) A ytt document that declares default values and type information for parameterized values.
* [Data Value](https://carvel.dev/ytt/docs/latest/ytt-data-values/) A ytt document that overrides defaults declared in a Data Values Schema.
* [Schemas Object](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#schema-object): The `components.schemas` section of an OpenAPI Document that defines the input and output data types.
* Data Values Overlay: a Data Values document preceded by either a Data Values or Data Values Schema file.

## References:
- [document spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#openapi-object)
- [info object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#info-object)
- [schema object spec](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#schemaObject)
