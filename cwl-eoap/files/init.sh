#!/bin/bash

cd /workspace

git clone 'https://github.com/eoap/cwl-eoap.git'

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir stactools rasterio requests stac-asset click-logging tabulate tqdm pystac-client ipykernel loguru scikit-image rio_stac 

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_eoap_env --display-name "Python (CWL EOAP)"