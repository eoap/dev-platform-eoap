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
/workspace/.venv/bin/python -m pip install --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" || exit $?
/workspace/.venv/bin/python -m pip install --upgrade "certifi>=2026.10.19" || exit $?
/workspace/.venv/bin/python -m pip install --no-cache-dir "odc-stac" ipykernel cwltool zarr matplotlib loguru click "graphviz" "pillow" "cwl-loader>=0.5.0" "eoap-cwlwrap" "plantuml" "cwl2puml>=0.8.0" stactools[validate] rioxarray

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_eoap_env --display-name "Python (EOAP)"