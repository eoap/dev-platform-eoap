#!/bin/bash

set -x 

export PATH=/workspace/.local/bin:/workspace/.venv/bin:$PATH

cd /workspace

git clone 'https://github.com/eoap/dask-app-package.git'

code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter
code-server --install-extension tamasfe.even-better-toml

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
            
pip install git+https://github.com/Terradue/calrissian@dask-gateway tomlq # calrissian and tomlq (for task files)

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir numpy==1.26.3 dask==2024.1.0 distributed==2024.1.0 dask-gateway==2024.1.0 pystac bokeh rioxarray==0.18.1 loguru==0.7.3 odc-stac[botocore]==0.3.10 stackstac==0.5.1 pystac-client planetary-computer xarray-spatial "xarray[complete]" ipykernel rio-color
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


curl -s -L https://github.com/pypa/hatch/releases/latest/download/hatch-x86_64-unknown-linux-gnu.tar.gz | tar -xzvf - -C /workspace/.venv/bin/
chmod +x /workspace/.venv/bin/hatch

curl -s -L https://github.com/go-task/task/releases/download/v3.41.0/task_linux_amd64.tar.gz | tar -xzvf - -C /workspace/.venv/bin/
chmod +x /workspace/.venv/bin/task

curl -s -LO https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64.tar.gz 
tar -xvf yq_linux_amd64.tar.gz
mv yq_linux_amd64 /workspace/.venv/bin/yq

curl -s -L https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 > /workspace/.venv/bin/skaffold
chmod +x /workspace/.venv/bin/skaffold
