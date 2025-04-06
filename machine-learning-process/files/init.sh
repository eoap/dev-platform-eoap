#!/bin/bash

set -x 
cd /workspace


# Setup workspace
mkdir machine-learning-process
git clone https://github.com/parham-membari-terradue/machine-learning-process.git
cd machine-learning-process

# Install VS Code Extensions
code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter
ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

# Setup user settings
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

# Setup Python virtual environment
python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir tomlq calrissian 


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

# AWS environment variables
export AWS_DEFAULT_REGION="far-par"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_BUCKET_NAME="ai-ext-bucket-dev"
export AWS_S3_ENDPOINT="https://s3.fr-par.scw.cloud"
export MLFLOW_TRACKING_URI="http://my-mlflow:5000"
export TASK_X_REMOTE_TASKFILES="1"
export PATH=$PATH:/workspace/.venv/bin
