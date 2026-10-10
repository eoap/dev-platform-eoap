#!/usr/bin/env bash
set -euo pipefail
run_dir=/calrissian/dask-acceptance/$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$run_dir"
echo "Dask acceptance artifacts: $run_dir"
CWLTOOL_OPTIONS= /opt/calrissian-venv/bin/calrissian --dask-gateway-url "$DASK_GATEWAY_ADDRESS" --max-ram 2G --max-cores 2 --pod-serviceaccount calrissian-sa --outdir "$run_dir/results" --tmp-outdir-prefix "$run_dir/tmp/" --tool-logs-basepath "$run_dir/logs" --usage-report "$run_dir/usage.json" /workspace/dask-app-package/cwl-workflows/gateway-acceptance.cwl > "$run_dir/outputs.json" 2> "$run_dir/execution.log" || { tail -n 40 "$run_dir/execution.log"; exit 1; }
cat "$run_dir/results/report.json"
/workspace/.venv/bin/python - <<'PY'
from dask_gateway import Gateway
import time
with Gateway() as gateway:
    for attempt in range(30):
        if not gateway.list_clusters():
            print('Dask cluster disposal passed')
            break
        time.sleep(1)
    else:
        raise RuntimeError('Dask cluster was not disposed')
PY
