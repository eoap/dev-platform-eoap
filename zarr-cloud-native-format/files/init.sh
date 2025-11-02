#!/bin/bash

cd /workspace

git clone 'https://github.com/eoap/zarr-cloud-native-format.git'

code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir "odc-stac" ipykernel cwltool zarr matplotlib loguru click "graphviz" "pillow" "cwl-loader>=0.5.0" "eoap-cwlwrap" "plantuml" "cwl2puml>=0.8.0" stactools[validate] rioxarray

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_eoap_env --display-name "Python (EOAP)"