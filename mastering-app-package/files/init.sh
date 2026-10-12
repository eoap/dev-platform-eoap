#!/bin/bash

# The shared chart invokes this file through sh.
if [ -z "${BASH_VERSION:-}" ]; then
    exec /bin/bash "$0" "$@"
fi
set -euo pipefail

cd /workspace

release_tag=${APPLICATION_PACKAGE_VERSION:-}
training_ref=${TRAINING_REF:-}
if [ -n "$training_ref" ]; then
    git check-ref-format --allow-onelevel "$training_ref"
    if [ ! -d mastering-app-package/.git ]; then
        git clone --no-checkout 'https://github.com/eoap/mastering-app-package.git' mastering-app-package
        git -C mastering-app-package fetch origin "$training_ref"
        git -C mastering-app-package checkout --detach FETCH_HEAD
    elif [ -n "$(git -C mastering-app-package status --porcelain)" ]; then
        echo "Preserving local training checkout and edits; skipping checkout of $training_ref"
    else
        git -C mastering-app-package fetch origin "$training_ref"
        git -C mastering-app-package checkout --detach FETCH_HEAD
    fi
elif [ -n "$release_tag" ]; then
    git check-ref-format "refs/tags/$release_tag"
    if [ ! -d mastering-app-package/.git ]; then
        git clone --single-branch --branch "$release_tag" 'https://github.com/eoap/mastering-app-package.git'
        git -C mastering-app-package checkout --detach "refs/tags/$release_tag"
    elif [ -n "$(git -C mastering-app-package status --porcelain)" ]; then
        echo "Preserving local training checkout and edits; skipping release checkout $release_tag"
    else
        git -C mastering-app-package fetch origin "refs/tags/$release_tag"
        git -C mastering-app-package checkout --detach FETCH_HEAD
    fi
elif [ ! -d mastering-app-package/.git ]; then
    git clone --branch feature/metadata 'https://github.com/eoap/mastering-app-package.git'
elif [ -n "$(git -C mastering-app-package status --porcelain)" ]; then
    echo "Preserving local training checkout and edits; skipping automatic checkout and fast-forward"
else
    git -C mastering-app-package fetch origin feature/metadata
    git -C mastering-app-package checkout feature/metadata
    git -C mastering-app-package merge --ff-only FETCH_HEAD
fi

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter --install-extension eschalk0.scientific-data-viewer

python - <<'PY'
import json
from pathlib import Path
import subprocess
import tempfile
import urllib.request

with tempfile.TemporaryDirectory(prefix="eoap-extensions-") as directory:
    for repo in ("eoap-validator-vscode", "cwl-metadata-editor", "cwl-uml-viewer"):
        request = urllib.request.Request(
            f"https://api.github.com/repos/eoap/{repo}/releases/latest",
            headers={"Accept": "application/vnd.github+json", "User-Agent": "eoap-module-init"},
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            release = json.load(response)
        assets = [asset for asset in release["assets"] if asset["name"].endswith(".vsix")]
        if len(assets) != 1:
            raise RuntimeError(f"{repo}: expected one VSIX asset, found {len(assets)}")
        print(f"Installing {repo} {release['tag_name']}", flush=True)
        destination = Path(directory) / f"{repo}.vsix"
        with urllib.request.urlopen(assets[0]["browser_download_url"], timeout=120) as response:
            destination.write_bytes(response.read())
        subprocess.run(["code-server", "--install-extension", str(destination)], check=True)
PY

ln -sfn /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

python - <<'PY'
import json
from pathlib import Path

path = Path("/workspace/User/settings.json")
settings = json.loads(path.read_text()) if path.exists() else {}
settings.update({
    "workbench.colorTheme": "Visual Studio Dark",
    "python.defaultInterpreterPath": "/workspace/.venv/bin/python",
    "scientificDataViewer.python.overridePythonInterpreter": "/workspace/.venv/bin/python",
    "scientificDataViewer.python.useExtensionOwnEnvironment": False,
})
path.write_text(json.dumps(settings, indent=2) + "\n")
PY

# Match the Calrissian artifact installed in PDE, including its exact Git commit.
calrissian_requirement=$(/opt/calrissian-venv/bin/python - <<'PY'
from importlib.metadata import distribution
import json

package = distribution("calrissian")
provenance = json.loads(package.read_text("direct_url.json") or "{}")
vcs = provenance.get("vcs_info", {})
if vcs.get("vcs") == "git" and vcs.get("commit_id"):
    print(f"calrissian @ git+{provenance['url']}@{vcs['commit_id']}")
else:
    print(f"calrissian=={package.version}")
PY
)

uv venv --allow-existing --seed --python /opt/conda/bin/python /workspace/.venv
source /workspace/.venv/bin/activate
# Calrissian pins typing-extensions 4.8.0; newer Jupyter clients require 4.13+.
uv pip install --python /workspace/.venv/bin/python rasterio==1.5.2 click==8.5.0 pystac==1.15.2 loguru==0.7.3 pyproj==3.8.0 shapely==2.1.2 scikit-image pystac rio_stac "ipykernel==6.29.5" "jupyter-client==8.6.3" "stactools[validate]" \
    matplotlib==3.11.2 xarray==2026.9.0 rioxarray==0.23.0 \
    pandas==3.0.6 nose2==0.16.0 "$calrissian_requirement"
uv pip check --python /workspace/.venv/bin/python
/workspace/.venv/bin/python -m ipykernel install --user --name mastering_env --display-name "Python (Mastering Application Package)"

# # Newer training checkouts use a package-specific Hatch Bash kernel for each lab.
# if [ -f /workspace/mastering-app-package/scripts/register-hatch-kernel.py ]; then
#     # Isolate Hatch from the image's incompatible virtualenv installation.
#     uv tool install --force --with "virtualenv<21" hatch==1.16.2
#     export PATH="/workspace/.local/bin:$PATH"
#     for tool in crop norm_diff otsu stac; do
#         (
#             cd "/workspace/mastering-app-package/water-bodies/command-line-tools/$tool"
#             hatch run default:python /workspace/mastering-app-package/scripts/register-hatch-kernel.py "$tool"
#         )
#     done
# fi

# Use PDE's kubectl rather than downloading architecture-specific binaries.
mkdir -p /workspace/.aws
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set endpoint_url http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333
aws configure set s3.addressing_style path
chmod 600 /workspace/.aws/credentials

# SeaweedFS may start after the coder init container. Bound the readiness wait
# and create the bucket again whenever this init container runs.
endpoint=http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333
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
