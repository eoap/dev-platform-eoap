# eoap-contract-first development module

Deploy the `eoap-contract-first` training checkout in the EOEPCA PDE editor. The deployment
uses `eoepca/pde-code-server:amd64` and a dedicated authenticated SeaweedFS 4.48.0
release with disposable S3 data. Workspace and Calrissian PVCs are retained.

Run `task start` for the optional local Minikube setup, or select an existing
Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`. Then run `task test`,
`task cwl:docs`, and `task labs` using the same context. `task dev` forwards the
editor to localhost:8000. Configure the storage classes in `skaffold.yaml` for
your cluster; the supplied `standard` class is the tested local configuration.

Training source: https://github.com/eoap/eoap-contract-first. Feature-branch changes must be
published or copied into the persistent workspace before deploying them. Init
preserves existing edited checkouts. No registry or Git publication is performed
by the validation tasks.

S3 endpoint: `http://eoap-contract-first-s3-seaweedfs-all-in-one:8333`, region `us-east-1`,
path addressing, credentials `test`/`test`, initialized bucket `results`.
Only the AMD64 local Kubernetes configuration has been selected for acceptance;
other architectures and storage providers need their own validation.

## Contract-first tasks

The source's locked uv environment supplies the actual contract-derived tools.
`task labs` runs its `reference:test` gate: three contract entrypoints, formatter,
lint, strict typing, security, all 39 tests, supply-chain inventory/tests and
strict MkDocs build. These passed on 11 October 2026; the acceptance log is
`/workspace/contract-acceptance.log`. The reference scattered workflow uses the
real application and validates its STAC and raster outputs.

`task training:task TRAINING_TASK=workflow:run` executes the reference workflow;
`task cwl:docs` derives contract artifacts with transpiler-mate. Container and
registry integration are separate optional source tasks. Publication is gated
by the source repository and is not part of deployment acceptance.
The task wrapper clears the inherited `CWLTOOL_OPTIONS=--podman` so the
reference's explicit `--no-container` tests can execute.
