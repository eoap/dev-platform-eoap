# Develop typed standalone CWL

Use this guide when authoring a new learning example or migrating an existing one. Make the change in the training repository on a feature branch and update its notebook jobs and staging adapters together.

## Define the contract first

Declare `cwlVersion: v1.2`. Choose File/Directory for staged filesystem objects, records for structured values and enums for controlled choices. Keep secrets as appropriately handled secret values; a URI record is not an authentication mechanism.

A small URI record example:

```yaml
cwlVersion: v1.2
class: CommandLineTool
label: Inspect a scene reference
doc: Demonstrate a typed scene reference supplied to a command.
requirements:
  SchemaDefRequirement:
    types:
      - name: URI
        type: record
        fields:
          - name: value
            type: string
            doc: Absolute reference to the scene resource.
baseCommand: echo
inputs:
  scene:
    type: URI
    label: Scene reference
    doc: The scene URI to print; this example does not stage the resource.
    inputBinding:
      valueFrom: $(self.value)
outputs: []
```

The matching job is:

```yaml
scene:
  value: https://example.org/scenes/scene.json
```

This is a teaching fragment, not a release-ready EOAP: add required provenance metadata and meaningful outputs for your actual application. Wrapper APIs may require a canonical URI type identifier rather than the local `URI` name; use the module's existing convention consistently.

## Embed module-defined types

Place definitions in `SchemaDefRequirement` in the distributed CWL document. If composing a graph, verify every process using those types can resolve them in the final document. Check IDs and enum bindings after serialization, not only in the source template.

For STAC, retain this shared import exactly:

```yaml
- $import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml
```

Its presence is an agreed external dependency. Embedding your own types does not mean replacing the OGC schema. Preserve other existing approved/shared dependencies deliberately and record what validation fetches.

## Keep wrapping and serialization explicit

Use the module's `eoap-cwlwrap` composition and `cwl-loader.dump_cwl` serialization path. **Do not use `cwltool --pack`.** When the wrapper introduces a URI schema reference, embed the required definition into the distributed output using the module's helper while preserving shared OGC imports.

Update stage-in/out templates to accept the same records as notebook jobs. Check the final distributed document from an isolated location so an adjacent local schema cannot silently satisfy a missing definition.

## Validate documentation and behavior

Provide repository/version/license/author metadata, labels and descriptions for processes and ports. Use the repository's actual license and author information. Generate and inspect Markdown via the source tool, and run the deployment's `cwl:docs` acceptance path. An equivalent renderer's passing result is not automatically a claim of transpiler-mate compatibility; contract-first runs actual transpiler-mate derivation.

Exercise valid inputs and meaningful invalid ones. Confirm that the CLI receives the intended URI value, BBox ordering or CRS spelling. In particular, enum normalization and bindings must be checked at runtime. Assert failed application execution returns a nonzero result; a swallowed Python exception can otherwise make a notebook look successful.

See the [contract reference](../reference/cwl-contract.md) for acceptance requirements and the [validation guide](validate-a-module.md) for the complete sequence.
