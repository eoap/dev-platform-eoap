#!/usr/bin/env bash
set -euo pipefail
export PATH=/workspace/.venv/bin:$PATH
exec bash /workspace/dask-app-package/scripts/run-gateway-acceptance.sh
