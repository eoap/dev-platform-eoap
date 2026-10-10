# STAC training deployment

The module uses `eoepca/pde-code-server:amd64` and its own SeaweedFS Helm
release (chart 4.48.0). S3 data is disposable; workspace files remain on the
editor PVC. Initialization selects the `feature/typed-cwl-inputs` training
branch, preserves an existing dirty checkout, installs an isolated Python
environment using uv, and initializes the `results` bucket. Notebook and CWL
corrections live in the training repository rather than being rewritten at
startup.

The training feature branch must be pushed before a fresh deployment can clone
it. For local validation, copy that branch's changed files into the preserved
`/workspace/stac-eoap` checkout. Select another published compatible ref with
`STAC_TRAINING_REF` in the init environment; a typed-CWL source preflight prevents
running an older checkout with the new wrapping API.

From this directory, deploy to an existing Kubernetes cluster:

```bash
task deploy KUBE_CONTEXT=my-cluster
task test KUBE_CONTEXT=my-cluster
task labs:list KUBE_CONTEXT=my-cluster
task labs KUBE_CONTEXT=my-cluster
```

`task up` creates a local Minikube profile, loads a locally available PDE image,
and deploys and tests the module. `task dev KUBE_CONTEXT=my-cluster` watches
changes and forwards the editor to port 8000. Adjust the image and storage class
in `skaffold.yaml` for the target cluster. ARM64 has not been validated.

The five training notebooks live under `notebooks`; the shared runner saves
executed copies under `/workspace/lab-results/<UTC timestamp>` and leaves
source notebook outputs untouched. Select a notebook with `LAB`, and set the
per-cell timeout with `CELL_TIMEOUT`. The examples fetch public satellite data
and pull processing images from GHCR, so outbound access is required.

The S3 endpoint is `http://eoap-stac-s3-seaweedfs-all-in-one:8333`, using the
training credentials `test`/`test`, region `us-east-1`, and path addressing.

## AMD64 validation

On 10 October 2026, training commits `7e8fe5e` and `d9c92ec` on `feature/typed-cwl-inputs`
was copied into the preserved workspace on Kubernetes v1.35.1, context
`eoap-mastering-app-package-docker`, namespace `eoap-stac`. All five notebooks
passed with PDE and SeaweedFS. The composed typed stage-in/application/stage-out
workflow also executed successfully with cwltool/Podman and returned
`{stac_catalog: {value: "s3://results/run-005/catalog.json"}}`.

All six CWL documents validated, as did the packed wrapper. Invalid URI, BBox,
EPSG, and band inputs were rejected before processing. The stage-out root-link
fix was checked again through notebooks 03/05, direct typed CWL stage-out, and
the composed workflow. Catalog/item root links resolved within S3; all three
output paths had readable 1832 × 2359 binary `uint8` masks in EPSG:32611.
The CLI-uploaded asset also matched the local raster bytes.

The complete notebook run is `/workspace/lab-results/20261010T213756155207Z`.
Post-fix notebook checks are in `20261010T214255952481Z` and
`20261010T214516585446Z`. The wrapper summary and log are
`/workspace/stac-typed-wrapped-result.json` and
`/workspace/stac-typed-wrapped.log`. Host copies, including output integrity
checks and the packed workflow, are in `/tmp/stac-typed-artifacts`.

The training branch is committed locally and has not been pushed. A fresh
clone requires publishing it first. The validation uses the available AMD64
Minikube-backed cluster; ARM64 and other-cluster execution remain untested.

SeaweedFS pod recreation discarded the S3 sentinel and previous results.
The workspace sentinel and training files survived. Redeployment recreated
`results` and the Python environment, retaining its old copy as
`/workspace/.venv-pre-typed-backup`; dependency and editor/S3 checks passed.
Recreation exposed a missing explicit PyYAML dependency; training commit
`d9c92ec` and the init script now declare it. The wrapping notebook passed
with the recreated environment in `20261010T214902634272Z`. Lifecycle
evidence is in `/tmp/stac-typed-artifacts/lifecycle.json`.
