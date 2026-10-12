# CWL how-to deployment

This module uses `eoepca/pde-code-server:amd64`, its isolated Calrissian runtime,
and a module-specific SeaweedFS 4.48.0 release. Workspaces and Calrissian outputs
remain on retained PVCs; S3 data uses disposable `emptyDir` storage.

From this directory, target an existing Kubernetes cluster:

```bash
task deploy KUBE_CONTEXT=my-cluster
task test KUBE_CONTEXT=my-cluster
task cwl:docs KUBE_CONTEXT=my-cluster
task workflows KUBE_CONTEXT=my-cluster
```

`task up` optionally creates a Minikube profile and loads the local PDE image.
Change the image, storage classes, and resource settings for your cluster.
The raster examples request 2 GiB per conversion/stack task and 4 GiB for color
processing, with an 8 GB Calrissian suite budget. Allow additional memory for
the editor and storage pods. ARM64 and other-cluster execution are untested.

Initialization clones the published `2.0.0` tag from `https://github.com/eoap/how-to.git` inside the editor. No sibling host checkout is needed. Set `HOWTO_TRAINING_REF` to test a different published ref. Dirty checkouts and user files are preserved. uv synchronizes the hash-locked Python environment and registers `cwl_how_to_env`; Task, Skaffold, yq, and Calrissian come from PDE.

All ten source CWL documents use v1.2 and embedded custom types, with metadata checked by the training Markdown generator. The custom-types lesson defines URI and BBox records and CRS/band enums and processes three Sentinel-2 acquisitions around Lake Almanor. No `cwltool --pack` is used. `task workflows` runs all eleven cases from `project.toml` using Kubernetes Calrissian task pods and stops at a failure. Results, logs, and usage reports are under `/calrissian/how-to/<UTC timestamp>`.

The default S3 endpoint is
`http://eoap-how-to-s3-seaweedfs-all-in-one:8333`, with `test` credentials,
`us-east-1`, path addressing, and an initialized `results` bucket. The current
workflow examples use HTTP imagery and PVC outputs; S3 smoke checks validate
the deployment service separately.

## Stable 2.0.0 acceptance, 11 October 2026

[Stable release 2.0.0](https://github.com/eoap/how-to/releases/tag/2.0.0) includes the custom-types CWL and job. Publication CI [38149876345](https://github.com/eoap/how-to/actions/runs/38149876345) passed; downloaded asset checksums and the unchanged rio image digest were verified.

All ten standalone documents and generated Markdown passed validation. All eleven Calrissian cases passed from clean training commit `714ae39` with a fresh hash-locked Python environment. Evidence is retained in `/calrissian/how-to/20261011T144008Z`. The custom-types case verified three STAC items, binary water-mask pixels and raster bounds matching Lake Almanor. The equivalent CI suite and strict documentation build passed in [run 38148089234](https://github.com/eoap/how-to/actions/runs/38148089234).

The reprojection enum uses `EPSG4326`; its CLI binding emits `EPSG:4326`. Earlier editor HTTP, S3 roundtrip and deployment lifecycle checks passed. Workspace PVCs remain retained and S3 storage remains disposable.

For dedicated acceptance, the host's existing Minikube Docker profile was increased from an 8 GiB RAM cap to 64 GiB and its saved CPU allocation aligned to the host's 16 CPUs. The other training deployments were uninstalled while retaining their workspace and Calrissian PVCs.
