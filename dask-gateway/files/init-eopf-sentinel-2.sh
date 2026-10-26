#!/bin/bash

set -x 

cd /workspace

git clone 'https://github.com/eoap/dask-app-package.git'

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

pip install --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" || exit $?
pip install --upgrade "certifi>=2026.10.19" || exit $?
pip install --no-warn-script-location git+https://github.com/Terradue/calrissian@dask-gateway # calrissian

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

# eopf-sentinel-2 environment
python -m venv /workspace/.venv-eopf
source /workspace/.venv-eopf/bin/activate
/workspace/.venv-eopf/bin/pip install --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" || exit $?
/workspace/.venv-eopf/bin/pip install --upgrade "certifi>=2026.10.19" || exit $?
/workspace/.venv-eopf/bin/pip install --upgrade "uv>=0.13.4"
/workspace/.venv-eopf/bin/python -m uv pip install numpy==1.26.3 dask==2025.4.0 distributed==2025.4.0 dask-gateway==2025.4.0 pystac bokeh rioxarray==0.18.1 loguru==0.7.3 odc-stac[botocore]==0.3.10 stackstac==0.5.1 pystac-client==0.8.6 planetary-computer==1.0.0 xarray-spatial==0.4.0 "xarray[complete]==2025.4.0" ipykernel rio-color==2.0.1
res=$?
if [ $res -ne 0 ]; then
    echo "Failed to install packages"
    exit $res
fi


cd /workspace/dask-app-package/cloudless-mosaic
/workspace/.venv-cloudless-mosaic/bin/python -m uv pip install --no-cache-dir -e .

/workspace/.venv-cloudless-mosaic/bin/python -m ipykernel install --user --name dask-gateway --display-name "Python (Cloudless Mosaic Dask Application Package)"


export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-dask-gateway-localstack:4566



