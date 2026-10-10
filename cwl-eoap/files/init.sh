#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

training_ref=${CWL_EOAP_TRAINING_REF:-feature/pde-typed-cwl}
if [ ! -d cwl-eoap/.git ]; then
    git clone --branch "$training_ref" 'https://github.com/eoap/cwl-eoap.git'
elif [ -n "$(git -C cwl-eoap status --porcelain)" ]; then
    echo "Preserving local cwl-eoap checkout and edits"
else
    git -C cwl-eoap fetch origin "$training_ref"
    git -C cwl-eoap checkout "$training_ref"
    git -C cwl-eoap merge --ff-only FETCH_HEAD
fi
if [ ! -f cwl-eoap/scripts/cwl-docs.py ]; then
    echo "cwl-eoap typed-CWL training source is required; select $training_ref or copy the feature branch into the workspace" >&2
    exit 1
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
ln -sfn /opt/calrissian-venv/bin/calrissian /workspace/.venv/bin/calrissian
# Calrissian remains in the container-provided isolated environment.
uv pip install --python /workspace/.venv/bin/python PyYAML rasterio requests pystac click loguru pyproj shapely ipykernel nbclient nbformat bash_kernel check-jsonschema yq cwltool
/workspace/.venv/bin/python cwl-eoap/scripts/cwl-docs.py --output /tmp/howto-cwl-docs
/workspace/.venv/bin/python -m bash_kernel.install
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name cwl_env --display-name "Python (cwl-eoap)"

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-cwl-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials
endpoint=http://eoap-cwl-s3-seaweedfs-all-in-one:8333
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
