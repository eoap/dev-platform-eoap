#!/usr/bin/env bash
set -euo pipefail
context=$1
namespace=$2
shift 2
settings_dir=$(mktemp -d)
trap 'rm -rf "$settings_dir"' EXIT
kubectl --context "$context" -n "$namespace" get configmap zarr-publication-settings -o json > "$settings_dir/settings.json"
kubectl --context "$context" -n "$namespace" get secret zarr-s3-credentials -o json > "$settings_dir/credentials.json"
python - "$settings_dir" <<'PY' | kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- /workspace/.venv/bin/python /workspace/zarr-cloud-native-format/scripts/publish-s3.py "$@"
import json,base64,sys
from pathlib import Path
root=Path(sys.argv[1])
settings=json.loads(json.loads((root/'settings.json').read_text())['data']['settings.json'])
credentials=json.loads((root/'credentials.json').read_text())['data']
settings.update({key:base64.b64decode(credentials[key]).decode() for key in ('accessKey','secretKey')})
print(json.dumps(settings))
PY
kubectl --context "$context" -n "$namespace" rollout restart deployment/zarr-stac-api deployment/titiler-eopf
kubectl --context "$context" -n "$namespace" rollout status deployment/zarr-stac-api --timeout=300s
kubectl --context "$context" -n "$namespace" rollout status deployment/titiler-eopf --timeout=300s
# Readiness can precede propagation of the new Service endpoints.
kubectl --context "$context" -n "$namespace" exec deployment/code-server-deployment -c code-server -- python -c '
import time, urllib.request
for attempt in range(30):
    try:
        for url in ("http://titiler-eopf-client:8080/api/_mgmt/health", "http://titiler-eopf-client:8080/stac/collections"):
            urllib.request.urlopen(url, timeout=2).read()
        print("STAC and TiTiler proxy endpoints ready")
        break
    except Exception:
        if attempt == 29:
            raise
        time.sleep(1)
'
