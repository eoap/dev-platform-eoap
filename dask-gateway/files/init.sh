#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/dask-app-package.git'

code-server --install-extension ms-python.python 
#code-server --install-extension redhat.vscode-yaml
#code-server --install-extension sbg-rabix.benten-cwl
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

pip install --no-warn-script-location git+https://github.com/Terradue/calrissian@dask-gateway # calrissian

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/pip install --upgrade uv
/workspace/.venv/bin/python -m uv pip install --no-cache-dir numpy==1.26.3 dask==2025.4.0 distributed==2025.4.0 dask-gateway==2025.4.0 pystac bokeh rioxarray==0.18.1 loguru==0.7.3 odc-stac[botocore]==0.3.10 stackstac==0.5.1 pystac-client==0.8.6 planetary-computer==1.0.0 xarray-spatial==0.4.0 "xarray[complete]==2025.4.0" ipykernel rio-color==2.0.1
res=$?
if [ $res -ne 0 ]; then
    echo "Failed to install packages"
    exit $res
fi

/workspace/.venv/bin/python -m ipykernel install --user --name dask-gateway --display-name "Python (Dask Application Package)"


export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-dask-gateway-localstack:4566



