# inference-eoap development module

Deploy the `inference-eoap` training checkout in the EOEPCA PDE editor. The deployment
uses `eoepca/pde-code-server:amd64` and a dedicated authenticated SeaweedFS 4.48.0
release with disposable S3 data. Workspace and Calrissian PVCs are retained.

Run `task start` for the optional local Minikube setup, or select an existing
Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`. Then run `task test`,
`task cwl:docs`, and `task labs` using the same context. `task dev` forwards the
editor to localhost:8000. Configure the storage classes in `skaffold.yaml` for
your cluster; the supplied `standard` class is the tested local configuration.

Training source: https://github.com/eoap/inference-eoap. Feature-branch changes must be
published or copied into the persistent workspace before deploying them. Init
preserves existing edited checkouts. No registry or Git publication is performed
by the validation tasks.

S3 endpoint: `http://eoap-inference-s3-seaweedfs-all-in-one:8333`, region `us-east-1`,
path addressing, credentials `test`/`test`, initialized bucket `results`.
Only the AMD64 local Kubernetes configuration has been selected for acceptance;
other architectures and storage providers need their own validation.

## Local inference acceptance

`task labs:fixture` runs all six notebooks in dependency order with the deterministic
13-band local staging fixture selected for acceptance. The actual ONNX model
executes in Python, Podman, CommandLineTool and workflow paths. Use
`task labs:run LAB=<notebook>` for a single lab. This validates inference and
portable staging; it does not validate authenticated Copernicus downloading.
For that path, run the staging notebook interactively with
`EOAP_INFERENCE_LOCAL_FIXTURE=0` and existing CDSE credentials in environment
variables. The notebook does not print bearer tokens.

## Preparing 2.0.0 with real input

`task labs` now selects authenticated real-data acceptance. Put Copernicus S3
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in the platform's ignored `.env`,
then run `task labs KUBE_CONTEXT=<context>`. Use `ENV_FILE=<path>` for another
credential file. The host runner sends credentials over Kubernetes exec stdin
instead of placing them in the kubectl command line or Git checkout. It redacts
logs and executed notebooks; SeaweedFS retains its separate training credentials.

The stage-in tool uses the current CDSE STAC endpoint and downloads all 66 files
of the real lesson SAFE product. All thirteen bands are converted to 10 m COGs
and classified by the actual ONNX model. `task test:science` compares output
dimensions, CRS, transform, bounds, class range and the last edge-chip prediction
against the real staged rasters and model. No generated pixels establish release
acceptance. Full-tile processing uses an editor limit of 8 CPUs and 24 GiB RAM.

Initialization pins published commit `39cab01` from `feature/pde-typed-cwl` and
preserves edited workspaces and unpublished feature commits. CI validates regressions and
contracts, builds all three locked containers and publishes immutable candidate
images/CWL on feature pushes. Stable publication waits for authenticated notebook
and candidate artifact acceptance. Older fixture results below are historical
development checks, not evidence that 2.0.0 is release ready.

All three standalone CWL documents and generated Markdown passed validation.
All six notebooks passed on 11 October 2026; the application-step run is under
`/workspace/lab-results/20261010T223933938539Z`, container/CLT under
`20261010T224327413465Z`/`20261010T224338075925Z`, workflow/scenario under
`20261010T224351792719Z`/`20261010T224406323521Z`. The partial-batch regression
also passed. Editor HTTP, S3 roundtrip and retained-workspace/fresh-environment/
disposable-S3 lifecycle checks passed.

## Accepted 2.0.0 candidate

[Candidate CI](https://github.com/eoap/inference-eoap/actions/runs/38171221762)
published `2.0.0-rc.55` from clean source `39cab01`. All six notebooks passed
against that exact source with authenticated CDSE S3 downloads of the complete
66-file SAFE product. Seven regressions, three standalone contracts, strict
documentation and editor/S3 smoke passed. Published candidate CWL also passed
real Calrissian execution; all checked classification rasters are 10980×10980
with the original input CRS, transform and bounds, valid model classes, and the
correct last edge-chip prediction. Checksums and anonymous image manifests passed.

Evidence and immutable image references are recorded in
[acceptance/2.0.0-rc.55.json](acceptance/2.0.0-rc.55.json).
[PR #1](https://github.com/eoap/inference-eoap/pull/1) prepares 2.0.0; stable
promotion/publication is pending. Acceptance covers AMD64 Minikube and CDSE S3;
OAuth token downloading and other architectures/clusters remain untested.

To validate downloaded candidate artifacts on your selected cluster:

```sh
gh run download 38171221762 --repo eoap/inference-eoap \
  --name inference-2.0.0-rc.55 --dir /tmp/inference-candidate
task test:kubernetes KUBE_CONTEXT=<context> \
  PACKAGE=/tmp/inference-candidate/tile-based-classification.2.0.0-rc.55.cwl
```

Run authenticated labs first to produce the real staged input. Allocate enough
workspace capacity for complete SAFE products, COGs, retained runs and image caches
on storage providers that enforce the requested volume size.
