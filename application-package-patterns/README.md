# Application package patterns module

Deploy [application-package-patterns 2.0.0](https://github.com/eoap/application-package-patterns/releases/tag/2.0.0) in the EOEPCA PDE editor. Initialization clones the published GitHub tag and preserves edited checkouts. Deployment needs only this dev-platform-eoap checkout, outbound access and the PDE image; no sibling training clone is required.

The module uses `eoepca/pde-code-server:amd64` and dedicated authenticated SeaweedFS (chart 4.48.0). Workspace and Calrissian PVCs are retained; S3 uses disposable storage. Select an existing Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`, or use `task start` for local Minikube. Configure the storage classes in `skaffold.yaml` for your cluster; `standard` was used for local acceptance. Run subsequent tasks with the same context.

- `task test`: deployment readiness, editor HTTP and S3 upload/download/delete.
- `task cwl:docs`: standalone CWL contract and metadata validation.
- `task wrap`: compose standalone workflows through eoap-cwlwrap.
- `task labs`: all twelve real-data patterns and four optional-port cases through Calrissian.
- `task test:lifecycle`: retained workspace, fresh environment and disposable S3 checks; run after saving outputs.
- `task dev`: editor forwarding to localhost:8000.

Lessons are Markdown pages backed by executable CWL. The Python 3.12 environment is hash-locked. The staging lock records published mastering 2.0.1 stage-in/out CWL and container digests on GHCR. The typed stage-in adapter downloads the required green/red/nir08 assets with a 300-second timeout; DEM staging uses native stac-asset transfers and signing. Stage-out disables upload caching and assigns distinct S3 prefixes to scattered results.

The release publishes fourteen original and twelve wrapped CWL packages, with portable transpiler-mate OCI annotations. For example, `ghcr.io/eoap/application-package-patterns/cwl/pattern-1:2.0.0` exposes the local File/Directory application, while `ghcr.io/eoap/application-package-patterns/cwl/pattern-1-wrapped:2.0.0` adds typed URI staging and S3 publication. Typed remote-input jobs accompany the wrapped execution path. Publication verifies immutable pull-backs, annotations, file contents and CWL entrypoints.

S3 endpoint: `http://eoap-application-package-patterns-s3-seaweedfs-all-in-one:8333`; region `us-east-1`, path addressing, training credentials `test`/`test`, bucket `results`.

All sixteen cases passed from fresh checkout/environment `c02c778` on AMD64 Minikube, using the published stable staging dependencies. The promoted/tagged commit `0774ea9` has the same tree. [Release CI](https://github.com/eoap/application-package-patterns/actions/runs/38157522966) passed all sixteen cases, 27 runner tests, 26 OCI metadata checks, strict documentation and publication verification. Every published package also resolves anonymously. Scientific checks cover resolvable STAC links, readable georeferenced rasters intersecting the requested area, distinct output catalogs and a finite normalized-index mean for the scalar case.

Evidence: `/workspace/lab-results/patterns-c02c778-stable.zip` and `/calrissian/patterns-stable/20261011T165020Z`. Earlier lifecycle checks passed and retained edited workspaces; the final stable-dependency run followed them. Other architectures and Kubernetes storage/network configurations require their own acceptance.
