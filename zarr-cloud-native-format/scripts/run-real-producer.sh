#!/usr/bin/env bash
set -euo pipefail
context=${1:-eoap-mastering-app-package-docker}
namespace=${2:-zarr-cloud-native-format}
version=${3:-${ZARR_RELEASE_VERSION:-2.0.0}}
run="/calrissian/us-lake-$(date -u +%Y%m%dT%H%M%SZ)"
kubectl --context "$context" -n "$namespace" exec -i deployment/code-server-deployment -c code-server -- /workspace/.venv/bin/python - "$run" "$version" <<'PYCODE'
from pathlib import Path
from urllib.request import urlopen
import sys
import yaml
run = Path(sys.argv[1])
version = sys.argv[2]
run.mkdir(parents=True)
base = 'https://github.com/eoap/zarr-cloud-native-format/releases/download/' + version
with urlopen(base + '/app-water-bodies.' + version + '.cwl', timeout=120) as response:
    text = response.read().decode()
document = yaml.safe_load(text)
assert document['s:softwareVersion'] == version
assert ':latest' not in text and ':local' not in text
(run / 'producer.cwl').write_text(text)
url = 'https://raw.githubusercontent.com/eoap/zarr-cloud-native-format/' + version + '/cwl-tests/jobs/producer-job-item.yml'
with urlopen(url, timeout=120) as response:
    (run / 'job.yml').write_bytes(response.read())
PYCODE
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
