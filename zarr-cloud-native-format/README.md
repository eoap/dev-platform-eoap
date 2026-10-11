# Zarr cloud native format

Deploy the PDE editor, SeaweedFS, a GeoParquet-backed STAC API, upstream TiTiler-EOPF **0.12.2**, and the module's Leaflet HTML client. The producer outputs are staged to S3; TiTiler resolves their STAC assets through the API and reads Zarr data directly from SeaweedFS. No database is needed.

## Deploy and open

The viewer is included in this platform checkout at `viewer/index.html`; Skaffold packages it into the client deployment. Stage-out uses mastering's published `2.0.0` GHCR container pinned by digest, verified against real Sentinel-2 GeoZarr output. The course source is cloned from GitHub by initialization. Deployment copies only cluster publication settings into the GitHub checkout; no sibling training checkout is required.

```sh
cd zarr-cloud-native-format
task deploy KUBE_CONTEXT=eoap-mastering-app-package-docker
task test
task viewer
```

Open <http://localhost:8090>. The client uses `/stac/` for metadata and `/api/` for per-asset TiTiler routes, through the same Nginx origin. API documentation is at <http://localhost:8090/api/api.html>. `task dev` forwards editor/API/client ports 8000/8010/8090; run `task training:sync` after deployment to copy unpublished module changes when using this command.

The namespace contains these services:

| Service | Port | Purpose |
|---|---|---|
| `code-server-service` | 8080 | Learning editor |
| `zarr-s3-seaweedfs-all-in-one` | 8333 | S3-compatible storage |
| `zarr-stac-api` | 8080 | STAC API over a GeoParquet metadata index |
| `titiler-eopf` | 8080 | Upstream 0.12.2 tile server |
| `titiler-eopf-client` | 8080 | HTML client and same-origin proxy |

Other clusters require suitable storage classes, image build/push settings and a registry reachable by their nodes. Shared RWO mounts use affinity with the editor. Acceptance here covers the AMD64 Docker-backed Minikube context.

## Publish and display outputs

Use **item-mode** producer results: `cwl-tests/jobs/producer-job-item.yml`. The updated writer references the complete Zarr store and generates group-based multiscale layout entries supported by TiTiler 0.12.2.

```sh
task viewer:publish RESULTS=/workspace/zarr-cloud-native-format/cwl-tests/results.json
# Or stage a completed catalog directly:
task viewer:publish DATA_ROOT=/calrissian/results/my-run
# An already staged wrapped-workflow result is indexed without another upload:
task viewer:publish RESULTS=/workspace/zarr-cloud-native-format/cwl-tests/results-s3.json
task test:viewer
```

The publication task executes an **eoap-cwlwrap** workflow with mastering's stage-out tool using the PDE's isolated Calrissian environment. It uploads the complete Zarr store, rewrites STAC links and returns a catalog URI. Only after successful upload does it generate the metadata index and refresh the STAC API and TiTiler. Each run receives a unique S3 prefix.

Credentials and the resolved stage-out image come from the deployed Secret/ConfigMap. Temporary job files containing credentials are removed after execution. Local output paths must be visible in the editor under `/workspace` or `/calrissian`.

The GeoParquet index preserves asset URLs, render definitions and time metadata. A portable `items.parquet` is stored alongside the catalog in S3. The STAC API queries an atomic local mirror in `titiler-index` on the shared PVC; the Zarr arrays are read directly from S3. Publishing the same collection ID replaces its active index, while other collection IDs remain available. Old version files and S3 prefixes remain for inspection.

The defaults are collection/item `water-bodies` and asset `measurements`. Collection/item IDs can be changed in the viewer form; configure other defaults in `chart/values.yaml`. The client resolves render expressions against advertised variable names, including root names such as `ndwi`.

Published STAC Items include `tilejson` links for NDWI and water classification, with `bidx=1` selecting the first acquisition. They use root-relative viewer paths (`/api/...`). XYZ templates are obtained from TileJSON rather than embedded in the STAC Item.

## Reproduce the S3 rendering checks

```sh
task test:viewer:fixture
```

This publishes a separate `viewer-smoke-fixture` collection containing synthetic data near Venice. It leaves `water-bodies` unchanged. It tests the writer, stage-out, index and tile services; it does not validate EO processing.

To validate real EO processing, run:

```sh
task test:producer:real
```

This builds and loads the processing containers into Minikube, discovers real Sentinel-2 L2A scenes over the Northern California lake area for June 2021, executes the complete producer with Calrissian, publishes its output to S3, and verifies both California bounds and rendered tiles. Logs and results remain in a timestamped `/calrissian/us-lake-*` directory. The image loading step targets this repository's Minikube environment; the CWL processing workflow can run on other Kubernetes clusters when its images are available in a registry.

The module's producer lab now includes a wrapping step. Its `cwl:wrap:producer` task generates a standalone CWL v1.2 graph with the final catalog's stage-out; the wrapper uses mastering’s published stable stage-out image. No packing command is used. See the [training publication guide](https://github.com/eoap/zarr-cloud-native-format/blob/feature/zarr-conventions/docs/how-to/titiler-eopf-kubernetes.md).

## Configuration and storage lifecycle

TiTiler's upstream 0.12.2 image is pinned by digest. Its `TITILER_EOPF_STAC_API_URL` points at `zarr-stac-api`; S3 endpoint and credentials target SeaweedFS. The historical local-reader patch image is no longer built by this deployment. The GeoParquet API dependencies are pinned to a tested compatible set, and DuckDB extensions are bundled into its image.

SeaweedFS uses chart 4.48.0 and disposable `emptyDir` storage, matching other modules. Default training credentials are `test`/`test`, bucket `results`, region `us-east-1`. Change matching credentials in `seaweedfs-values.yaml` and `chart/values.yaml`. After a SeaweedFS pod replacement, recreate the bucket and republish outputs: the retained metadata index may reference objects that were removed with disposable storage. The fixture task republishes generated data after the bucket is available.

Client scripts and map backgrounds require browser access to the public CDN/OSM services.
