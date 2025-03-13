#!/bin/bash

set -x 
cd /workspace

# Install Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/

# Install yq (YAML processor)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# Setup workspace
mkdir machine-learning-process-new
git clone https://github.com/parham-membari-terradue/machine-learning-process-new.git
cd machine-learning-process-new

# Install VS Code Extensions
code-server --install-extension ms-python.python 
code-server --install-extension ms-toolsai.jupyter
ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

# Setup user settings
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

# Setup Python virtual environment
python -m pip install --no-cache-dir hatch tomlq calrissian go-task-bin

# Add ~/.local/bin to PATH for current session
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
source ~/.bashrc

# AWS environment variables
export AWS_DEFAULT_REGION="far-par"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_BUCKET_NAME="ai-ext-bucket-dev"
export AWS_S3_ENDPOINT="https://s3.fr-par.scw.cloud"
export MLFLOW_TRACKING_URI="http://my-mlflow:5000"
export TASK_X_REMOTE_TASKFILES="1"
