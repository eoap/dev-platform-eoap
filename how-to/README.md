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

Initialization selects `feature/pde-typed-cwl` from the sibling how-to training
repository. Publish its commits before fresh clones can use it. Local testing
may seed the persistent checkout from that feature branch. Dirty checkouts and
user files are preserved. uv installs the module environment and registers
`cwl_how_to_env`; Task, Skaffold, yq, and Calrissian come from PDE.

All nine source CWL documents use v1.2 and embedded URI/JSON records and
band/CRS enums, with metadata checked by the training Markdown generator.
No `cwltool --pack` is used. `task workflows` runs the ten cases from
`project.toml` using Kubernetes Calrissian task pods and stops at a failure.
Results, logs, and usage reports are under `/calrissian/how-to/<UTC timestamp>`.

The default S3 endpoint is
`http://eoap-how-to-s3-seaweedfs-all-in-one:8333`, with `test` credentials,
`us-east-1`, path addressing, and an initialized `results` bucket. The current
workflow examples use HTTP imagery and PVC outputs; S3 smoke checks validate
the deployment service separately.

## AMD64 acceptance, 11 October 2026

All nine standalone documents and their generated Markdown passed validation.
All ten Calrissian workflow cases passed on Kubernetes. Evidence is retained in
`/calrissian/how-to/20261010T221938Z` (first two cases),
`20261010T222253Z` (six subsequent cases), and `20261010T223841Z` (reprojection
and final scatter). The reprojection enum uses `EPSG4326`; its CLI binding emits
`EPSG:4326`. Editor HTTP and S3 upload/download/delete checks passed.
`task test:lifecycle` recreated the environment, retained the old environment
and workspace sentinel, discarded the old S3 object, and initialized `results`.
