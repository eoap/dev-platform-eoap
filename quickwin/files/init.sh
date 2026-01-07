#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/quickwin.git'

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv

source /workspace/.venv/bin/activate

/workspace/.venv/bin/python -m pip install --no-cache-dir rasterio click pystac loguru pyproj shapely scikit-image pystac rio_stac ipykernel stactools[validate]

/workspace/.venv/bin/python -m ipykernel install --user --name quickwin_env --display-name "Python (Quickwin)"

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-quickwin-localstack:4566