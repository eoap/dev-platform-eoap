# E-learning module and CWL contract

These are the requirements agreed in [PLAN.md](../../PLAN.md). Apply them to changes in the training repository as well as its deployment here.

## Required interfaces

| Requirement | Acceptance evidence |
| --- | --- |
| CWL v1.2 | Every affected distributed CWL document validates with `cwlVersion: v1.2` |
| Typed inputs and outputs | Records/enums/File/Directory match application semantics and example jobs |
| Standalone definitions | Module-defined types resolve within the distributed document, including composed packages |
| Shared schemas retained | STAC retains the approved OGC import; external dependencies are explicit |
| Metadata and readable documentation | Repository/version/license/author, process labels/docs and described typed ports validate with the selected renderer |
| Existing composition path | eoap-cwlwrap and dump_cwl where applicable; no `cwltool --pack` |
| Source changes on feature branches | Preserve WIP in each affected repository |
| Conventional Commits | Scope and message describe the actual change |

“Standalone” here means module-owned type definitions are included in the EOAP document. It does not mean removing explicitly retained shared schemas, container image references, remote input data or runtime dependencies.

## Metadata fields

The migrated equivalent-renderer examples use a schema.org namespace and fields such as `s:softwareVersion`, `s:codeRepository`, `s:license` and `s:author`, alongside CWL `label` and `doc`. Use genuine repository provenance and license declarations; do not copy metadata from an unrelated module.

Include descriptions for input and output ports, meaning/units for records, permitted values for enums and output expectations. Generated documentation must accurately describe the job structure the notebook supplies.

Exact validation is owned by the source tool: several modules have `scripts/cwl-docs.py`; contract-first derives artifacts through actual transpiler-mate tooling. A local equivalent renderer is an acceptance path allowed by the plan, but does not itself establish compatibility with every transpiler-mate version or metadata expectation.

## Validation layers

- Schema/type validation checks the syntax and resolvability of the final distributed document.
- Metadata/documentation validation checks what a learner and downstream renderer can understand.
- Invalid-input checks demonstrate rejection of a meaningful bad job, rather than merely accepting the examples.
- Runtime checks confirm bindings, staging, container invocation and output semantics agree with the typed contract.

Validate from isolated copies with a controlled external-fetch policy when the module tool supports it. Otherwise a neighboring schema file may hide a missing embedded type. A shared OGC fetch being allowed is different from a module-owned schema remaining external.

## Practical conventions

URI records carry a `value` field. A BBox record carries coordinates and a CRS; use the exact schema required by the module. Enums for bands and CRS must match actual binding behavior. Staged paths use File/Directory objects, not URI records masquerading as filesystem paths.

Keep stage-in/out, composed workflow ports and notebook job examples synchronized. For results, assert catalog/item/asset link resolution and readability. For process errors, preserve nonzero exit status and useful diagnostics. Containers and code must not report success after caught processing failures.

Use the [typed-CWL guide](../how-to/develop-typed-cwl.md) to make a change and the [acceptance guide](../how-to/validate-a-module.md) to test it.
