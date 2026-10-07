#!/bin/bash

set -x 

cd /workspace

git clone --depth=1 'https://github.com/eoap/mastering-app-package.git'
rm -rf /workspace/mastering-app-package/.git

curl -LJO https://github.com/eoap/cwl-metadata-editor/releases/download/v0.3.0/cwl-metadata-editor-v0.3.0.vsix
code-server --install-extension cwl-metadata-editor-v0.3.0.vsix
rm -rf cwl-metadata-editor-v0.3.0.vsix

code-server --install-extension ms-python.python 
code-server --install-extension redhat.vscode-yaml
code-server --install-extension sbg-rabix.benten-cwl
code-server --install-extension ms-toolsai.jupyter
code-server --install-extension eschalk0.scientific-data-viewer

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
. /workspace/.venv/bin/activate

# Use pip directly: uv can segfault under AMD64 emulation on ARM64 Minikube.
/workspace/.venv/bin/python -m pip install --no-cache-dir \
  rasterio==1.5.2 \
  click==8.5.0 \
  pystac==1.15.2 \
  loguru==0.7.3 \
  pyproj==3.8.0 \
  shapely==2.1.2 \
  scikit-image==0.26.0 \
  rio-stac==0.12.0 \
  ipykernel==7.4.0 \
  'stactools[validate]==0.5.3' \
  nose2==0.16.0 \
  pandas==3.0.6 \
  matplotlib==3.11.2

res=$?
if [ $res -ne 0 ]; then
    echo "Failed to install packages"
    exit $res
fi

/workspace/.venv/bin/python -m ipykernel install --user --name mastering_env --display-name "Python (Mastering Application Package)"

echo "**** install kubectl ****" 
curl -s -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  
chmod +x kubectl                                                                                                    
mv ./kubectl /workspace/.venv/bin/kubectl

export AWS_DEFAULT_REGION="us-east-1"

export AWS_ACCESS_KEY_ID="test"

export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-mastering-app-package-localstack:4566
