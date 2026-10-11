#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then exec /bin/bash "$0" "$@"; fi
set -euo pipefail
cd /workspace
training_ref=${ZARR_TRAINING_REF:-feature/zarr-conventions}
if [ ! -d zarr-cloud-native-format/.git ]; then
    git clone --branch "$training_ref" https://github.com/eoap/zarr-cloud-native-format.git
elif [ -n "$(git -C zarr-cloud-native-format status --porcelain)" ]; then
    echo 'Preserving local Zarr training checkout and edits'
else
    git -C zarr-cloud-native-format fetch origin "$training_ref"
    git -C zarr-cloud-native-format checkout "$training_ref"
    git -C zarr-cloud-native-format merge --ff-only FETCH_HEAD
fi
code-server --install-extension ms-python.python --install-extension ms-toolsai.jupyter --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User
printf '%s\n' '{"workbench.colorTheme":"Visual Studio Dark"}' > /workspace/User/settings.json
uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
uv pip install --python /workspace/.venv/bin/python ipykernel nbclient nbformat cwltool matplotlib loguru click graphviz pillow PyYAML rioxarray "cwl-loader==0.27.0" "eoap-cwlwrap==0.32.0" "cwl2puml==0.49.1" "stactools[validate]" -e /workspace/zarr-cloud-native-format/command-line-tools/stac-zarr
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name cwl_eoap_env --display-name 'Python (Zarr EOAP)'
mkdir -p /workspace/zarr-cloud-native-format/titiler-runs
