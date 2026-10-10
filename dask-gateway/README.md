# Dask application package module

This folder deploys the `dask-app-package` course: PDE, upstream Calrissian's
Dask Gateway integration, Dask Gateway, and authenticated disposable SeaweedFS.
All three editor profiles share the same initialization and S3 endpoint.

Use `task deploy KUBE_CONTEXT=<context>`, `task test`, and `task cwl:docs`.
The optional `task start` starts Minikube. Configure the storage classes for your
cluster. Use `task labs LAB=eopf-sentinel-2/notebook.ipynb` or
`task labs LAB=cloudless-mosaic/notebook.ipynb` for a chosen notebook.
Full satellite jobs require considerably more resources than deployment smoke tests.

The training feature branch is `feature/pde-typed-cwl`; publish or copy that
checkout into the persistent workspace for testing. Calrissian comes from the
PDE isolated environment. There is no Terradue Calrissian fork installation.

Typed URI, Date, BBox, and SpectralBand definitions are embedded in each CWL
application package. Upstream Calrissian requires `clusterMaxCores` (plural).
Application images must also contain compatible Dask scheduler/worker commands;
Calrissian selects the application's image when provisioning its Dask cluster.

The gateway chart is pinned to 2025.4.0 to match the course client and application
images, following the [Dask custom-image guidance](https://gateway.dask.org/install-kube.html#using-a-custom-image).

## Matching notebook workers

PDE notebooks use Python 3.12. Published course images use Python 3.10, which
failed Dask task deserialization when used from the PDE client. Build the
matching worker from the sibling training feature checkout before local use:

```bash
task worker:build
task worker:load MINIKUBE_PROFILE=<running-profile>
task deploy KUBE_CONTEXT=<context>
```

`Dockerfile.pde-worker` installs both course packages and their shared
`requirements-runtime.txt` lock on Python 3.12.11. The editor installs the same
lock. The supplied worker tag is `eoap-dask-worker:2025.4.0-py312`; for another
cluster, make this image available to its runtime or publish your worker image
and change the backend and `daskGateway.image` settings. No worker image is
published by these tasks. The legacy Dockerfile/CI builds remain unchanged
pending the repository-wide image retirement decision.

Notebook tasks default to two workers. Cloudless validation uses `MAX_ITEMS=2`
(default in the task); set a larger value for the original full search. Use
`DASK_MAX_WORKERS` and `DASK_WORKER_CORES_LIMIT` for larger cluster budgets.

## Validation on the local AMD64 cluster

The bounded Calrissian two-worker job, cluster teardown, editor/S3 smoke checks,
and retained-workspace/fresh-environment lifecycle checks passed. The real
cloudless notebook passed with two satellite items and matching Python 3.12
workers. Five regression tests cover nonzero processing failures and current
`proj:code`/legacy `proj:epsg` metadata. Full EOPF notebook acceptance remains
blocked by HTTP 500 from its remote STAC item endpoint; this is not a passed
scientific workflow. Worker images remain local and ARM64 is untested.
