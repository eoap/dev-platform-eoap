#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/advanced-tooling.git'

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
/workspace/.venv/bin/python -m pip install --no-cache-dir tomlq calrissian
/workspace/.venv/bin/python -m ipykernel install --user --name advanced_tooling --display-name "Python (Advanced Tooling)"

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"
export PATH=$PATH:/workspace/.venv/bin

aws s3 mb s3://results --endpoint-url=http://eoap-advanced-tooling-localstack:4566

exit 0