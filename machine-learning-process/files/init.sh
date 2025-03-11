#!/bin/bash

set -x 
cd /workspace

#temp
mkdir machine-learning-process
git clone https://github.com/parham-membari-terradue/machine-learning-process.git
cd machine-learning-process


code-server --install-extension ms-python.python 
code-server --install-extension ms-toolsai.jupyter
ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir hatch

export AWS_DEFAULT_REGION="far-par"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_BUCKET_NAME="ai-ext-bucket-dev"
export AWS_S3_ENDPOINT="https://s3.fr-par.scw.cloud"
export MLFLOW_TRACKING_URI="http://localhost:5000"