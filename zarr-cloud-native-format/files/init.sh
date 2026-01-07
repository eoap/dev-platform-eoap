#!/bin/bash

cd /workspace

git clone 'https://github.com/eoap/zarr-cloud-native-format.git'

wget https://open-vsx.org/api/ms-python/python/2025.16.0/file/ms-python.python-2025.16.0.vsix
code-server --install-extension ms-python.python-2025.16.0.vsix

wget https://open-vsx.org/api/ms-toolsai/jupyter/2025.9.1/file/ms-toolsai.jupyter-2025.9.1.vsix
code-server --install-extension ms-toolsai.jupyter-2025.9.1.vsix

code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir "odc-stac" ipykernel cwltool zarr matplotlib loguru click "graphviz" "pillow" "cwl-loader>=0.5.0" "eoap-cwlwrap" "plantuml" "cwl2puml>=0.8.0" stactools[validate] rioxarray

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_eoap_env --display-name "Python (EOAP)"