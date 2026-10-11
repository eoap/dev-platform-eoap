# Quickwin development module

Quickwin uses the local AMD64 pilot image `eoepca/pde-code-server:amd64` and a
separate SeaweedFS Helm release (chart 4.48.0, image 4.48). The shared coder image
default remains unchanged. ARM64 and a published PDE manifest digest are pending.

From this directory, use:

```bash
task up
task test
task labs:list
task labs
task dev
task stop
```

These tasks require Task, Docker, Minikube, Helm, kubectl, Skaffold, and the local
PDE image. The default Docker-backed profile is `eoap-quickwin`, with 4 CPUs and
8192 MiB. Override `MINIKUBE_PROFILE` to target an existing cluster. Run one
module editor at a time on a node sized for one module. `task up` runs deployment
smoke checks; notebook execution is a separate command.

Initialization selects `feature/typed-cwl-release` from GitHub by default; set
`QUICKWIN_TRAINING_REF` to test another ref. Existing dirty training checkouts
are preserved. The source contains the container UID/GID fix; startup no longer
rewrites notebooks. The Python 3.12 environment is installed from the module's
hash-locked requirements with uv and checked before the editor starts.

Both standalone CWL documents use v1.2 with embedded URI/BBox records and CRS
and band enums. The notebook jobs use these contracts. `quickwin_env` runs the
Python lesson; PDE's Bash kernel and Podman run the container and CWL lessons.
The module-owned runner detects Bash errors as well as Jupyter errors. A full
`task labs` run also verifies four STAC catalogs, readable georeferenced masks,
binary mask values, and bounds intersecting Lake Almanor. Executed notebooks
are saved under unique `/workspace/lab-results/` directories. Select a notebook
with `task labs LAB='1 - Application.ipynb'`; later lessons depend on preceding
outputs. A partial run does not perform the full scientific acceptance check.

Use `KUBE_CONTEXT` for an existing Kubernetes cluster; `MINIKUBE_PROFILE` selects
the optional local-cluster helpers. `task deploy`, `task test`, `task labs`, and
`task dev` use the selected context. `task test:lifecycle` recreates the editor
environment and disposable S3 while preserving workspace PVCs and backing up
the old environment. It discards S3 objects, so run it after processing checks.

AWS CLI uses credentials `test` / `test`, region `us-east-1`, path addressing,
and endpoint `http://eoap-quickwin-s3-seaweedfs-all-in-one:8333`. Initialization
waits for S3 and creates `results`. Smoke checks upload, download, compare, and
remove a temporary object.

SeaweedFS objects use disposable `emptyDir` storage; pod recreation or release
removal loses them. A container restart in the same pod can retain data.
Recreating just the storage pod also removes its buckets; recreate `results`
with AWS CLI or restart the editor to rerun initialization. The chart's
credential Secret can remain after uninstall and contains no S3 objects.

The coder chart retains the workspace PVC on Helm uninstall. Reinstalling the
same release in the same namespace reuses its files; remove the PVC explicitly
only when its contents can be discarded. Published-image selection, ARM64,
and the remaining modules are covered in [the migration plan](../PLAN.md).

Validation on 10 October 2026 passed on Docker-backed Minikube profile
`eoap-mastering-app-package-docker`, namespace `eoap-quickwin`: fresh deployment,
editor HTTP 200, S3 upload/download/delete, and all four notebooks (application,
container build/run, CWL CommandLineTool, and CWL workflow). The training source
was `f81b825` with the container UID fix. That fix was also saved uncommitted in
`/data/work/github-com/eoap/quickwin`; initialization applies the same adjustment
to fresh checkouts. No training source was pushed during that initial pilot. The later release-preparation work is published on `feature/typed-cwl-release`.

Executed notebooks are under `/workspace/lab-results/20261010T202811545301Z/`
(application passed; initial container failure retained) and
`/workspace/lab-results/20261010T203209631926Z/` (successful container/CWL rerun).
Host copies are `/tmp/quickwin-migration-initial` and
`/tmp/quickwin-migration-container-cwl`. Mastering's editor was scaled to zero
during Quickwin validation to fit the node; its workspace volumes were retained.

## 2.0.0 release preparation evidence

[PR #7](https://github.com/eoap/quickwin/pull/7) contains the published feature
commits. Clean GitHub acceptance of `a98a0c9` passed all four real Sentinel-2
notebooks, four scientific STAC/GeoTIFF checks, isolated CWL validation, actual
transpiler-mate metadata checks and strict MkDocs build:
[accepted CI run](https://github.com/eoap/quickwin/actions/runs/38160206253).
Executed CI notebooks are copied to `/tmp/quickwin-ci-accepted-a98a0c9` on the
validation host.

Deployment, editor/S3 smoke, and the user-approved lifecycle check passed on AMD64 Minikube context
`eoap-mastering-app-package-docker`, namespace `eoap-quickwin`. A clean feature
checkout is preserved at `/workspace/quickwin-acceptance-a98a0c9`; its first
notebook failed on a truncated real COG tile transfer. The original tile needed
1,477,634 bytes, but the diagnostic read received only 571,623. Independent
range transfers also time out from the host. This is a remaining local acceptance
gate, despite successful real-data CI. Failed notebooks are retained under
`/workspace/lab-results/20261011T173443017308Z`.

Lifecycle evidence is in `/tmp/quickwin-lifecycle.log`; the old environment is
retained at `/workspace/.venv-before-lifecycle-20261011T173840Z`. The recreated
environment passed dependency checks, the workspace sentinel survived, the
pre-restart S3 object was discarded and `results` was recreated.

The old pilot workspace is preserved at `/workspace/quickwin-preserved-20261011`.
Only Quickwin remains deployed; other module PVCs are retained. The feature is
prepared for 2.0.0, but no new stable release or GHCR processing image has been
published. Rerun the full `task labs` once reliable remote raster access is
restored, then promote the accepted feature and dispatch publication from main.
