# Dask application package module

Deploy the `eoap/dask-app-package` course with PDE, upstream Calrissian's Dask
Gateway integration, Dask Gateway 2025.4.0, and disposable authenticated
SeaweedFS. The module targets Kubernetes; `task start` optionally creates a
Minikube cluster. Configure storage classes for your cluster.

## Deploy the accepted candidate

Initialization checks out immutable GitHub commit `f428aed` from
`feature/pde-typed-cwl`. The gateway and notebook worker use the public
`ghcr.io/eoap/dask-app-package/cloudless-mosaic:2.0.0-rc.69` image pinned to its
accepted digest. No sibling host checkout or local worker build is required.

```bash
task deploy KUBE_CONTEXT=<context>
```

[Acceptance CI](https://github.com/eoap/dask-app-package/actions/runs/38165235375)
passed before publishing the image. The EOPF package alias contains the same
runtime; artifact checksums and both immutable image references were verified.
An actual anonymous worker pull passed. Candidate artifacts are available from
that CI run; stable 2.0.0 has not been promoted or published.

The platform no longer republishes legacy Dask editor/client/worker images;
course image publication belongs to `eoap/dask-app-package` acceptance CI.
For custom development, `task worker:build` builds from the pinned GitHub source
and `task worker:load MINIKUBE_PROFILE=<profile>` loads the local candidate tag.
Configure both backend and `daskGateway.image` values to use a custom image.
Override `DASK_TRAINING_REF` in the editor environment when selecting another
training ref. Initialization preserves dirty workspaces; create a feature branch
before modifying course source and use conventional commits.

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

Candidate `2.0.0-rc.69` is accepted for the bounded AMD64 course cases. Six
regressions, standalone contracts, actual metadata-model validation, strict
docs, distributed creation/computation/disposal, both real EO notebooks and
both typed scientific CWL jobs passed in clean Kubernetes CI. The same real
notebooks and jobs passed on Minikube from clean commit `98a5899`; later changes
only adjust acceptance/CI budgets and documentation. All five raster assets
passed geographic and scientific checks, and gateway clusters were disposed.

Review [PR #11](https://github.com/eoap/dask-app-package/pull/11), promote the
accepted feature, and explicitly dispatch stable publication before claiming
2.0.0 is released. ARM64 and full-tile capacity remain unverified. The bounded
acceptance scope is not a full-acquisition capacity guarantee.
