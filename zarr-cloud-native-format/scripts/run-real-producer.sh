#!/usr/bin/env bash
set -euo pipefail
context=${1:-eoap-mastering-app-package-docker}
namespace=${2:-zarr-cloud-native-format}
module=$(cd "$(dirname "$0")/../../.." && pwd)/zarr-cloud-native-format
run="/calrissian/us-lake-$(date -u +%Y%m%dT%H%M%SZ)"
tag="us-lake-$(date -u +%Y%m%dT%H%M%SZ)"
task --dir "$module" containers:build:producer
tar -C "$module" -cf - cwl-workflow/app-water-bodies.cwl cwl-tests/jobs/producer-job-item.yml |
  kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- tar -C /workspace/zarr-cloud-native-format -xf -
for image in crop norm-diff otsu stac-collection stac-zarr stac-eopf-product; do
  docker tag "$image:latest" "$image:$tag"
  minikube -p "$context" image load "$image:$tag"
done
kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- /workspace/.venv/bin/python - "$run" "$tag" <<'PY'
from pathlib import Path
import sys
run = Path(sys.argv[1])
run.mkdir(parents=True)
root = Path('/workspace/zarr-cloud-native-format')
text = (root / 'cwl-workflow/app-water-bodies.cwl').read_text()
text = text.replace('ramMax: 512', 'ramMin: 2048\n        ramMax: 2048')
for name in ('crop', 'norm-diff', 'otsu', 'stac-collection', 'stac-zarr', 'stac-eopf-product'):
    text = text.replace(f'dockerPull: {name}:latest', f'dockerPull: {name}:{sys.argv[2]}')
(run / 'producer.cwl').write_text(text)
(run / 'job.yml').write_text((root / 'cwl-tests/jobs/producer-job-item.yml').read_text())
PY
kubectl --context "$context" -n "$namespace" exec deployment/code-server-deployment -c code-server -- bash -c '
  set -euo pipefail
  run=$1
  env -u CWLTOOL_OPTIONS /opt/calrissian-venv/bin/calrissian \
    --max-cores 2 --max-ram 6G --tool-logs-basepath "$run/tool-logs" --tmp-outdir-prefix "$run/tmp" \
    --outdir "$run/outputs" --pod-nodeselectors /etc/calrissian/pod-node-selector.yaml \
    "$run/producer.cwl#water-bodies" "$run/job.yml" > "$run/results.json" 2> "$run/run.log"
' bash "$run"
"$(dirname "$0")/publish-s3.sh" "$context" "$namespace" --results "$run/results.json"
kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- env EXPECT_US_LAKE=1 /workspace/.venv/bin/python - < "$(dirname "$0")/test-viewer.py"
echo "Real EO processing, S3 publication and rendering passed. Run: $run"
