#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

training_ref=${STAC_TRAINING_REF:-0.0.1}
if [ ! -d stac-eoap/.git ]; then
    git clone --branch "$training_ref" 'https://github.com/eoap/stac-eoap.git'
elif [ -n "$(git -C stac-eoap status --porcelain)" ]; then
    echo "Preserving local STAC checkout and edits"
else
    git -C stac-eoap fetch origin "$training_ref"
    git -C stac-eoap checkout "$training_ref"
    git -C stac-eoap merge --ff-only FETCH_HEAD
fi
if [ ! -f stac-eoap/scripts/cwl-docs.py ] || [ ! -f stac-eoap/requirements-notebooks.txt ]; then
    echo "STAC typed-CWL source and notebook dependency lock are required; update the preserved checkout to a compatible published ref" >&2
    exit 1
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
# Use the current EOEPCA Python wrapping API.
if [ -f /workspace/stac-eoap/requirements/development.txt ]; then
    cd /workspace/stac-eoap
    uv pip sync --python /workspace/.venv/bin/python --require-hashes requirements/development.txt
    uv pip install --python /workspace/.venv/bin/python --no-deps --no-build-isolation -e .
    cd /workspace
else
    uv pip sync --python /workspace/.venv/bin/python --require-hashes /workspace/stac-eoap/requirements-notebooks.txt
fi
/workspace/.venv/bin/python stac-eoap/scripts/cwl-docs.py --output /tmp/stac-cwl-docs
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name stac_env --display-name "Python (STAC)"

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-stac-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials
endpoint=http://eoap-stac-s3-seaweedfs-all-in-one:8333
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
