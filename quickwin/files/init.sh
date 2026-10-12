#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

training_ref=${QUICKWIN_TRAINING_REF:-feature/typed-cwl-release}
if [ ! -d quickwin/.git ]; then
    git clone --branch "$training_ref" 'https://github.com/eoap/quickwin.git'
elif [ -n "$(git -C quickwin status --porcelain)" ]; then
    echo "Preserving local Quickwin checkout and edits"
else
    git -C quickwin fetch --tags origin "$training_ref"
    git -C quickwin checkout "$training_ref"
    git -C quickwin merge --ff-only FETCH_HEAD
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
uv pip sync --python /workspace/.venv/bin/python --require-hashes /workspace/quickwin/requirements-notebooks.txt
/workspace/.venv/bin/python /workspace/quickwin/scripts/cwl-docs.py --validate
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
