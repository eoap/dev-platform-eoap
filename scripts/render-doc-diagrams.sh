#!/usr/bin/env bash
# Regenerate committed SVGs using a local PlantUML JAR; no remote rendering.
set -euo pipefail
repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
plantuml_jar=${PLANTUML_JAR:-${1:-}}
if [[ -z "$plantuml_jar" || ! -f "$plantuml_jar" ]]; then
    echo 'Set PLANTUML_JAR or pass the path to a local PlantUML JAR.' >&2
    exit 2
fi
java -Djava.awt.headless=true -jar "$plantuml_jar" \
    -charset UTF-8 -tsvg -failfast2 -o ../svg \
    "$repository_root"/docs/diagrams/src/*.puml
