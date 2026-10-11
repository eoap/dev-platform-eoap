# Zarr cloud native format

Deploy the learning editor together with EOPF-Explorer/TiTiler-EOPF and the module's existing Leaflet JavaScript client. The server reads completed GeoZarr stores from the shared workspace or Calrissian output volume; both viewer deployments mount these volumes read-only.

## Deploy and open the viewer

The training clone must be at `../../zarr-cloud-native-format`, on `feature/zarr-conventions`, with its viewer changes. Skaffold builds `docker/titiler-eopf-patched/Dockerfile` and packages the HTML client in a ConfigMap from that checkout. The editor checks out the same branch; `task deploy` copies the local client and publication helper into the editor, so unpublished feature changes can be tested.

```sh
cd zarr-cloud-native-format
# Select an existing Kubernetes context. The PDE image must be available to its nodes.
task deploy KUBE_CONTEXT=eoap-mastering-app-package-docker
task test KUBE_CONTEXT=eoap-mastering-app-package-docker
task viewer KUBE_CONTEXT=eoap-mastering-app-package-docker
```

Open <http://localhost:8090>. The client calls `/api/` on the same origin; Nginx proxies it to `titiler-eopf:8080` and serves published STAC metadata under `/data/`. Browsers never need Kubernetes service DNS. `task dev` forwards the editor to port 8000, raw API to 8010, and client to 8090; Client edits trigger a new ConfigMap deployment; `task training:sync` refreshes the publication helper and source examples in the editor. The API documentation is at <http://localhost:8090/api/api.html>.

The two ClusterIP services are `titiler-eopf` and `titiler-eopf-client`. For other clusters, configure Skaffold image building/pushing and a registry reachable by the nodes, and adapt the coder chart's storage class. The viewer pods have required affinity with the editor so the RWO workspace volume stays on the same node. This deployment does not require an S3 server.

## Publish module outputs

Run the producer workflow from the training checkout in the editor, retaining its CWL result JSON. Publish the `zarr_stac_catalog` output:

```sh
task viewer:publish RESULTS=/workspace/zarr-cloud-native-format/cwl-tests/results.json
# Or publish a completed catalog directly:
task viewer:publish DATA_ROOT=/calrissian/results/my-run
# Then check rendering:
task test:viewer
```

Use paths visible inside the editor and mounted under `/workspace` or `/calrissian`. A catalog root contains `<collection>/<item>.zarr`, a Zarr v3 `zarr.json`, and the producer's STAC metadata. Publication atomically updates `titiler-data`, a symlink to that catalog root; it does not copy large arrays or replace an existing directory. The task restarts TiTiler because its process caches open datasets. Publish only completed stores, and avoid modifying a served store in place.

The defaults are collection and item ID `water-bodies`. Set other IDs in the viewer form or change `collectionId`/`itemId` in `chart/values.yaml`. Collection outputs supply render definitions and time values from `collection.json`; item outputs also expose item metadata. The client resolves STAC measurement names against TiTiler's advertised dataset keys.

## Validate the integration without downloading EO products

```sh
task test:viewer:fixture
```

This deliberately switches publication to a small local fixture. It generates two georeferenced raster dates, runs the module's actual `stac-zarr` writer with overviews and GeoZarr validation, and checks STAC metadata, dataset keys, same-origin TileJSON URLs, nonempty PNG pixels, and distinct time-selected tiles. It does not execute the full remote-data water-body workflow. Publish your producer results again to return to your learning outputs.

## TiTiler compatibility

The image uses the upstream local-store commit `b0beec2a9c44ff030e2eef5cfc4622bd9ac19565`, pinned by its GHCR digest in the training Dockerfile. Current upstream `main` uses a STAC API configuration and cannot be substituted for the filesystem reader in this deployment. The existing derived-image patch is guarded against unexpected upstream code and handles GeoZarr layout entries pointing to DataArrays, variable-specific overview selection, and nanosecond time selectors.

Client scripts and map backgrounds use public CDN/OSM services and need browser network access. The HTML client remains the module's existing Leaflet implementation.
