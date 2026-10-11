#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

training_ref=${INFERENCE_EOAP_TRAINING_REF:-39cab012f0e6cbc20e8391e81694ad41319b2295}
if [ ! -d inference-eoap/.git ]; then
    git clone 'https://github.com/eoap/inference-eoap.git'
fi
training_branch=$(git -C inference-eoap symbolic-ref --quiet --short HEAD || true)
training_upstream=$(git -C inference-eoap rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
if [ -n "$(git -C inference-eoap status --porcelain)" ]; then
    echo "Preserving local inference-eoap checkout and edits"
elif [[ "$training_branch" == feature/* ]] && { [ -z "$training_upstream" ] || [ "$(git -C inference-eoap rev-list --count "${training_upstream}..HEAD")" -gt 0 ]; }; then
    echo "Preserving local feature branch $training_branch and its commits"
else
    git -C inference-eoap fetch --tags origin "$training_ref"
    git -C inference-eoap checkout --detach FETCH_HEAD
fi
if [ ! -f inference-eoap/scripts/cwl-docs.py ]; then
    echo "inference-eoap typed-CWL training source is required; select $training_ref or copy the feature branch into the workspace" >&2
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
uv pip sync --python /workspace/.venv/bin/python --require-hashes /workspace/inference-eoap/requirements-notebooks.txt
/workspace/.venv/bin/python inference-eoap/scripts/cwl-docs.py --output /tmp/inference-cwl-docs
/workspace/.venv/bin/python -m bash_kernel.install
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name inference_env --display-name "Python (inference-eoap)"

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-inference-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials
endpoint=http://eoap-inference-s3-seaweedfs-all-in-one:8333
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
