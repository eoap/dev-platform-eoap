#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail
cd /workspace

training_ref=${MACHINE_LEARNING_TRAINING_REF:-feature/maturity-parity}
if [ ! -d machine-learning-process/.git ]; then
    git clone --branch "$training_ref" 'https://github.com/eoap/machine-learning-process.git'
elif [ -n "$(git -C machine-learning-process status --porcelain)" ]; then
    echo "Preserving local machine-learning-process checkout and edits"
else
    git -C machine-learning-process fetch origin "$training_ref"
    git -C machine-learning-process checkout "$training_ref"
    git -C machine-learning-process merge --ff-only FETCH_HEAD
fi
if [ ! -f machine-learning-process/scripts/check-contracts.py ]; then
    echo "machine-learning-process typed-CWL training source is required; select $training_ref or copy the feature branch into the workspace" >&2
    exit 1
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter
ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions
mkdir -p /workspace/User/
if [ ! -f /workspace/User/settings.json ]; then
    echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json
fi

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
ln -sfn /opt/calrissian-venv/bin/calrissian /workspace/.venv/bin/calrissian
# Calrissian remains in the container-provided isolated environment.
uv pip sync --python /workspace/.venv/bin/python --require-hashes /workspace/machine-learning-process/requirements/development.txt
uv pip install --python /workspace/.venv/bin/python --no-deps --no-build-isolation /workspace/machine-learning-process/training/make-ml-model /workspace/machine-learning-process/inference/make-inference /workspace/machine-learning-process/MLM
ln -sfn /opt/calrissian-venv/bin/calrissian /workspace/.venv/bin/calrissian
/workspace/.venv/bin/python /workspace/machine-learning-process/scripts/check-contracts.py --output /workspace/lab-results/cwl-docs
/workspace/.venv/bin/python -m bash_kernel.install
/workspace/.venv/bin/python -m ipykernel install --user --name ml_env --display-name "Python (machine-learning-process)"
uv pip check --python /workspace/.venv/bin/python
export MLFLOW_TRACKING_URI=http://my-mlflow:5000

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://tile-based-training-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials
endpoint=http://tile-based-training-s3-seaweedfs-all-in-one:8333
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
