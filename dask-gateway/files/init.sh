#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/dask-app-package.git'

code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir numpy==1.26.3 dask==2024.1.0 distributed==2024.1.0 dask-gateway==2024.1.0 pystac bokeh rioxarray==0.18.1 loguru==0.7.3 odc-stac[botocore]==0.3.10 stackstac==0.5.1 pystac-client planetary-computer
res=$?
if [ $res -ne 0 ]; then
    echo "Failed to install packages"
    exit $res
fi

/workspace/.venv/bin/python -m ipykernel install --user --name dask-gateway --display-name "Python (Dask Application Package)"

echo "**** install kubectl ****" 
curl -s -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  
chmod +x kubectl                                                                                                    
mv ./kubectl /workspace/.venv/bin/kubectl

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-dask-gateway-localstack:4566