# cwl-eoap development module

Deploy the `cwl-eoap` training checkout in the EOEPCA PDE editor. The deployment
uses `eoepca/pde-code-server:amd64` and a dedicated authenticated SeaweedFS 4.48.0
release with disposable S3 data. Workspace and Calrissian PVCs are retained.

Run `task start` for the optional local Minikube setup, or select an existing
Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`. Then run `task test`,
`task cwl:docs`, and `task labs` using the same context. `task dev` forwards the
editor to localhost:8000. Configure the storage classes in `skaffold.yaml` for
your cluster; the supplied `standard` class is the tested local configuration.

Training source: https://github.com/eoap/cwl-eoap. Initialization defaults to the
published `1.0.0` tag; use `CWL_EOAP_TRAINING_REF` for a published development ref.
Init preserves existing edited checkouts. No registry or Git publication is
performed by the validation tasks.

S3 endpoint: `http://eoap-cwl-s3-seaweedfs-all-in-one:8333`, region `us-east-1`,
path addressing, credentials `test`/`test`, initialized bucket `results`.
Only the AMD64 local Kubernetes configuration has been selected for acceptance;
other architectures and storage providers need their own validation.

## AMD64 acceptance, 11 October 2026

The standalone typed URI contract and generated Markdown passed validation.
All three notebooks passed, including real Podman builds and CWL execution.
Executed notebooks: `/workspace/lab-results/20261010T223540691204Z` (command-line
and container) and `20261010T223855163640Z` (package rerun after adding libexpat).
Editor HTTP, S3 upload/download/delete, fresh environment recreation, retained
workspace/old environment, and disposable S3 reset passed.

## Release 1.0.0 acceptance

All three notebooks passed from clean GitHub checkout `8d1c115` on Minikube
with a fresh hash-locked Python 3.12 environment and real Sentinel-2 data.
Executed notebooks remain on the editor PVC under
`/workspace/cwl-release-acceptance-8d1c115/notebooks/20261011T131118292822Z`.
Main commit `74c252c` has the identical file tree and passed
[acceptance CI](https://github.com/eoap/cwl-eoap/actions/runs/38142401563), including
notebook execution, standalone CWL/Markdown validation, and strict MkDocs build.
[Release 1.0.0](https://github.com/eoap/cwl-eoap/releases/tag/1.0.0) includes the
typed CWL example, job inputs, and locked Python requirements. The labs build
their teaching containers locally; no prebuilt processor image is required.
