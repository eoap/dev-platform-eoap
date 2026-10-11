# Dask application package module

Deploy the `eoap/dask-app-package` course with PDE, upstream Calrissian's Dask
Gateway integration, Dask Gateway 2025.4.0, and disposable authenticated
SeaweedFS. The module targets Kubernetes; `task start` optionally creates a
Minikube cluster. Configure storage classes for your cluster.

## Prepare and deploy the candidate

Initialization checks out the published GitHub branch `feature/pde-typed-cwl`
inside the editor. No sibling host checkout is required. During release
preparation, build the matching candidate from that GitHub source and make it
available to the cluster:

```bash
task worker:build
task worker:load MINIKUBE_PROFILE=<running-profile>
task deploy KUBE_CONTEXT=<context>
```

For another cluster, publish the worker image to an accessible registry and
configure the backend and `daskGateway.image` values. The temporary default is
`eoap-dask-worker:2.0.0-candidate`. Accepted CI builds will publish the shared
application/worker image under the existing cloudless-mosaic and
EOPF-sentinel-2 GHCR package names; the deployment will adopt a verified
published digest before stable promotion. These tasks do not publish images. The platform no longer republishes the
legacy Dask editor/client/worker images; course image publication belongs to
`eoap/dask-app-package` acceptance CI.

Python 3.12, Dask/Distributed/Gateway 2025.4.0 and the hash-locked course runtime
match between notebook clients and workers. Both processing commands and Dask
scheduler/worker executables are in the same image. The image defines UID 1001
for Calrissian's non-root jobs. The editor installs the notebook and build
locks with uv; Calrissian stays in PDE's isolated environment.

## Validate

```bash
task test KUBE_CONTEXT=<context>
task cwl:docs KUBE_CONTEXT=<context>
task test:dask KUBE_CONTEXT=<context>
task labs:all KUBE_CONTEXT=<context>
task test:cwl KUBE_CONTEXT=<context>
```

Smoke tests check readiness, editor HTTP and real S3 upload/download/delete.
The distributed test creates two workers, checks the computed result, and
verifies cluster disposal. `labs:all` runs both real-data notebook lessons and
checks STAC assets, GeoTIFF coordinates and scientific value ranges.
`test:cwl` executes both typed scientific CWL jobs through Calrissian.

Acceptance uses two real Sentinel-2 acquisitions at 100 m for cloudless mosaics
and a centred 1024-pixel window from the original real EOPF Zarr acquisition.
The EOPF window is explicit and its STAC footprint is derived from the output
GeoTIFF. Set `MAX_ITEMS` and `EOPF_WINDOW` for larger workloads; omit the window
when invoking the application directly to process the full tile. No synthetic
EO samples replace source imagery.

CWL v1.2 documents embed their URI, Date, BBox, CRS and SpectralBand types.
The CRS input is quoted EPSG code `"4326"`. Dask Gateway is a mandatory custom
requirement. Metadata is validated against transpiler-mate's actual model in
an isolated environment; its generic cwl2oci parser does not support the Dask
requirement. CWL packing is never used.

## Release preparation status

Locked dependencies, six regression tests, standalone CWL validation,
metadata validation and strict documentation builds passed. Minikube editor/S3
checks and the rebuilt Calrissian two-worker job passed, including cluster
teardown. Both real-data notebooks and geographic/scientific asset checks passed. Both typed scientific CWL jobs also passed, including all five raster checks
and cluster disposal. Clean-commit acceptance and publication CI are in progress; this is not a release-readiness assertion. ARM64 remains untested.
