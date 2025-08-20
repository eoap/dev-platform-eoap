#!/bin/bash

cd /workspace

git clone 'https://github.com/eoap/application-package-patterns.git'

code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json
echo '[
            {
                "key": "ctrl+c",
                "command": "workbench.action.terminal.copySelection",
                "when": "terminalFocus && terminalTextSelected"
            },
            {
                "key": "ctrl+v",
                "command": "workbench.action.terminal.paste",
                "when": "terminalFocus"
            }
            ]' > /workspace/User/keybindings.json
            
python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir stactools rasterio requests stac-asset click-logging tabulate tqdm pystac-client ipykernel loguru scikit-image rio_stac calrissian tomlq

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_how_to_env --display-name "Python (CWL How-To's)"

curl -s -L https://github.com/go-task/task/releases/download/v3.41.0/task_linux_amd64.tar.gz | tar -xzvf - -C /workspace/.venv/bin/
chmod +x /workspace/.venv/bin/task

curl -s -L https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 > /workspace/.venv/bin/skaffold
chmod +x /workspace/.venv/bin/skaffold

curl -s -LO https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz 
tar -xvf yq_linux_amd64.tar.gz
mv yq_linux_amd64 /workspace/.venv/bin/yq