#!/bin/bash

set -x 
cd /workspace


# Setup workspace
mkdir machine-learning-process
git clone https://github.com/eoap/machine-learning-process.git
cd machine-learning-process

# Install VS Code Extensions
code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

# Setup user settings
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

# Setup Python virtual environment
python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" || exit $?
/workspace/.venv/bin/python -m pip install --upgrade "certifi>=2026.10.19" || exit $?
/workspace/.venv/bin/python -m pip install --no-cache-dir tomlq calrissian yq backports.zoneinfo


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




chmod +x /workspace/.venv/bin/yq
# AWS environment variables
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export MLFLOW_TRACKING_URI="http://my-mlflow:5000"
export ARROW_TZDATA_DIR=/usr/share/zoneinfo
export TASK_X_REMOTE_TASKFILES="1"
export PATH=$PATH:/workspace/.venv/bin
