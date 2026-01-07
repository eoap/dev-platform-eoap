#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/advanced-tooling.git'

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/pip install --upgrade uv
/workspace/.venv/bin/python -m uv pip install --no-cache-dir tomlq calrissian
/workspace/.venv/bin/python -m ipykernel install --user --name advanced_tooling --display-name "Python (Application Package Patterns)"

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"
export PATH=$PATH:/workspace/.venv/bin

aws s3 mb s3://results --endpoint-url=http://eoap-advanced-tooling-localstack:4566

exit 0