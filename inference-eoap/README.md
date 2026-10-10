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

`task labs` runs all six notebooks in dependency order with the deterministic
13-band local staging fixture selected for acceptance. The actual ONNX model
executes in Python, Podman, CommandLineTool and workflow paths. Use
`task labs:run LAB=<notebook>` for a single lab. This validates inference and
portable staging; it does not validate authenticated Copernicus downloading.
For that path, run the staging notebook interactively with
`EOAP_INFERENCE_LOCAL_FIXTURE=0` and existing CDSE credentials in environment
variables. The notebook does not print bearer tokens.

All three standalone CWL documents and generated Markdown passed validation.
All six notebooks passed on 11 October 2026; the application-step run is under
`/workspace/lab-results/20261010T223933938539Z`, container/CLT under
`20261010T224327413465Z`/`20261010T224338075925Z`, workflow/scenario under
`20261010T224351792719Z`/`20261010T224406323521Z`. The partial-batch regression
also passed. Editor HTTP, S3 roundtrip and retained-workspace/fresh-environment/
disposable-S3 lifecycle checks passed.
