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

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/pip install --upgrade uv
/workspace/.venv/bin/python -m uv pip install --no-cache-dir stactools calrissian tomlq

/workspace/.venv/bin/python -m ipykernel install --user --name cwl_how_to_env --display-name "Python (Application Package patterns)"

cd /workspace
git clone https://github.com/EOEPCA/eoap-cwlwrap.git
cd eoap-cwlwrap
/workspace/.venv/bin/pip install --no-cache-dir -e .


export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-application-package-patterns-localstack:4566

rm -f /workspace/.venv/bin/yq

# for calrissian (eoap-cwlwrap uses a recent version of cwltool)
/workspace/.venv/bin/python -m uv pip install cwltool==3.1.20240708091337