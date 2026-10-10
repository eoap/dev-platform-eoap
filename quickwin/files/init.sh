#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

if [ ! -d quickwin/.git ]; then
    git clone 'https://github.com/eoap/quickwin.git'
fi

# The legacy notebook hard-codes UID 1000, while PDE runs as UID 1001.
# Update only that command argument; preserve all other notebook content.
python - <<'PYTHON'
from pathlib import Path
notebook = Path('/workspace/quickwin/practice-labs/2 - Container.ipynb')
if notebook.is_file():
    source = notebook.read_text()
    updated = source.replace('--user=1000:100', '--user=$(id -u):$(id -g)')
    if updated != source:
        notebook.write_text(updated)
PYTHON

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
# Use the Click version selected for the tested notebook environment.
uv pip install --python /workspace/.venv/bin/python rasterio click==8.1.8 pystac loguru pyproj shapely scikit-image rio_stac ipykernel "stactools[validate]"
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name quickwin_env --display-name "Python (Quickwin)"

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-quickwin-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials
endpoint=http://eoap-quickwin-s3-seaweedfs-all-in-one:8333
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
