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

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir tomlq calrissian
# /workspace/.venv/bin/python -m ipykernel install --user --name mastering_env --display-name "Python (Mastering Application Package)"

echo "**** install kubectl ****" 
curl -s -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  
chmod +x kubectl 
mkdir -p /workspace/.venv/bin                                                                                                   
mv ./kubectl /workspace/.venv/bin/kubectl


curl -s -L https://github.com/pypa/hatch/releases/latest/download/hatch-x86_64-unknown-linux-gnu.tar.gz | tar -xzvf - -C /workspace/.venv/bin/
chmod +x /workspace/.venv/bin/hatch
curl -s -L https://github.com/go-task/task/releases/download/v3.41.0/task_linux_amd64.tar.gz | tar -xzvf - -C /workspace/.venv/bin/
chmod +x /workspace/.venv/bin/task

curl -s -L https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 > /workspace/.venv/bin/skaffold
chmod +x /workspace/.venv/bin/skaffold

curl -s -LO https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz 
tar -xvf yq_linux_amd64.tar.gz
mv yq_linux_amd64 /workspace/.venv/bin/yq

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"
export PATH=$PATH:/workspace/.venv/bin

aws s3 mb s3://results --endpoint-url=http://eoap-advanced-tooling-localstack:4566

exit 0