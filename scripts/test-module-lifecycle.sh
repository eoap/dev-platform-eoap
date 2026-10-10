#!/usr/bin/env bash
# Verify disposable S3 and reproducible environments without deleting user PVCs.
set -euo pipefail
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 KUBE_CONTEXT NAMESPACE S3_DEPLOYMENT ENVIRONMENT_PATH" >&2
    exit 2
fi
context=$1
namespace=$2
s3_deployment=$3
environment_path=$4
endpoint="http://${s3_deployment}:8333"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_path="${environment_path}-before-lifecycle-${stamp}"
object_key="lifecycle/${stamp}"
kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- bash -s -- "$endpoint" "$object_key" "$environment_path" "$backup_path" <<'PREPARE'
set -euo pipefail
endpoint=$1
object_key=$2
environment_path=$3
backup_path=$4
printf 'retained user workspace\n' > /workspace/.eoap-lifecycle-sentinel
aws --endpoint-url "$endpoint" s3api put-object --bucket results --key "$object_key" --body /workspace/.eoap-lifecycle-sentinel >/dev/null
printf 'old environment preserved\n' > "$environment_path/.eoap-environment-sentinel"
mv "$environment_path" "$backup_path"
PREPARE
kubectl --context "$context" -n "$namespace" rollout restart "deployment/$s3_deployment"
kubectl --context "$context" -n "$namespace" rollout status "deployment/$s3_deployment" --timeout=300s
kubectl --context "$context" -n "$namespace" rollout restart deployment/code-server-deployment
kubectl --context "$context" -n "$namespace" rollout status deployment/code-server-deployment --timeout=1200s
kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- bash -s -- "$endpoint" "$object_key" "$environment_path" "$backup_path" <<'VERIFY'
set -euo pipefail
endpoint=$1
object_key=$2
environment_path=$3
backup_path=$4
test "$(cat /workspace/.eoap-lifecycle-sentinel)" = 'retained user workspace'
test -f "$backup_path/.eoap-environment-sentinel"
test ! -f "$environment_path/.eoap-environment-sentinel"
test -x "$environment_path/bin/python"
uv pip check --python "$environment_path/bin/python"
aws --endpoint-url "$endpoint" s3api head-bucket --bucket results
if aws --endpoint-url "$endpoint" s3api head-object --bucket results --key "$object_key" >/dev/null 2>&1; then
    echo 'The pre-restart S3 object unexpectedly survived' >&2
    exit 1
fi
python -c 'import urllib.request; assert urllib.request.urlopen("http://127.0.0.1:8080/healthz", timeout=10).status == 200'
echo "Lifecycle passed: user workspace and old environment retained; fresh environment and results bucket initialized; old S3 object discarded."
VERIFY
