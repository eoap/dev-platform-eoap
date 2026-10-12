# Documentation diagrams

The diagrams have editable PlantUML sources and committed SVG renders. Normal
MkDocs builds use the SVG files directly; they do not invoke a PlantUML server
or require Java. The architecture diagram uses PlantUML's Java-based Smetana
layout, so regeneration does not require Graphviz.

| Diagram | Documentation | Source | SVG |
| --- | --- | --- | --- |
| Platform architecture | [Architecture](../explanation/architecture.md) | [PlantUML](src/platform-architecture.puml) | [SVG](svg/platform-architecture.svg) |
| Module acceptance | [Validation guide](../how-to/validate-a-module.md) | [PlantUML](src/module-acceptance.puml) | [SVG](svg/module-acceptance.svg) |
| Storage lifecycle | [Storage explanation](../explanation/storage-and-environments.md) | [PlantUML](src/storage-lifecycle.puml) | [SVG](svg/storage-lifecycle.svg) |
| Source synchronization | [Training source guide](../how-to/work-with-training-source.md) | [PlantUML](src/source-to-deployment.puml) | [SVG](svg/source-to-deployment.svg) |

## C4 architecture views

| Level | Documentation | Source | SVG |
| --- | --- | --- | --- |
| System context | [Level 1](../explanation/c4/system-context.md) | [PlantUML](src/c4-system-context.puml) | [SVG](svg/c4-system-context.svg) |
| Containers | [Level 2](../explanation/c4/containers.md) | [PlantUML](src/c4-containers.puml) | [SVG](svg/c4-containers.svg) |
| Components | [Level 3](../explanation/c4/components.md) | [PlantUML](src/c4-components.puml) | [SVG](svg/c4-components.svg) |
| Code | [Level 4](../explanation/c4/code.md) | [PlantUML](src/c4-runner-code.puml) | [SVG](svg/c4-runner-code.svg) |

The [C4 overview](../explanation/c4/README.md) defines notation, audiences and the selected zoom boundaries. These static structure diagrams complement the existing sequence/activity views.

## Regenerate the SVGs

Install Java and obtain the official
[PlantUML 1.2026.8 JAR](https://github.com/plantuml/plantuml/releases/download/v1.2026.8/plantuml.jar).
The renderer used for these artifacts has SHA-256:

```text
5e1ecfa8ecd32c90b03bbf3b1eb6f020943f98ab0fcf4032be31a0002ee2c462
```

From the repository root:

```bash
PLANTUML_JAR=/path/to/plantuml.jar task docs:diagrams
task docs:build -- --strict
```

Alternatively, pass the local JAR to the rendering script:

```bash
bash scripts/render-doc-diagrams.sh /path/to/plantuml.jar
```

Edit the `.puml` sources and shared `src/theme.iuml`, regenerate, and review both
source and SVG changes together. Keep generated SVGs in version control; do
not commit the JAR or temporary PNG previews. Check diagram labels against the
actual task/configuration behavior before updating the documentation.
