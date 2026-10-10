#!/bin/bash

# The shared chart invokes this file through sh.
if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail

cd /workspace

if [ ! -d mastering-app-package/.git ]; then
    git clone 'https://github.com/eoap/mastering-app-package.git'
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir rasterio click pystac loguru pyproj shapely scikit-image pystac rio_stac ipykernel "stactools[validate]" matplotlib pandas nose2
/workspace/.venv/bin/python -m ipykernel install --user --name mastering_env --display-name "Python (Mastering Application Package)"

# Use PDE's kubectl and isolated upstream Calrissian rather than installing
# architecture-specific binaries or shadowing Calrissian in the module venv.
mkdir -p /workspace/.aws
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials

# SeaweedFS may start after the coder init container. Bound the readiness wait
# and create the bucket again whenever this init container runs.
endpoint=http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333
ready=0
for attempt in {1..120}; do
    if aws --endpoint-url "$endpoint" --cli-connect-timeout 2 --cli-read-timeout 2 s3api list-buckets >/dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 2
done
if [ "$ready" != 1 ]; then
    echo "SeaweedFS S3 did not become ready" >&2
    exit 1
fi
if ! aws --endpoint-url "$endpoint" s3api head-bucket --bucket results >/dev/null 2>&1; then
    aws --endpoint-url "$endpoint" s3api create-bucket --bucket results
fi
