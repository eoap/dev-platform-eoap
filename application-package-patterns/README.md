# application-package-patterns development module

Deploy the `application-package-patterns` training checkout in the EOEPCA PDE editor. The deployment
uses `eoepca/pde-code-server:amd64` and a dedicated authenticated SeaweedFS 4.48.0
release with disposable S3 data. Workspace and Calrissian PVCs are retained.

Run `task start` for the optional local Minikube setup, or select an existing
Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`. Then run `task test`,
`task cwl:docs`, and `task labs` using the same context. `task dev` forwards the
editor to localhost:8000. Configure the storage classes in `skaffold.yaml` for
your cluster; the supplied `standard` class is the tested local configuration.

Training source: https://github.com/eoap/application-package-patterns. Feature-branch changes must be
published or copied into the persistent workspace before deploying them. Init
preserves existing edited checkouts. No registry or Git publication is performed
by the validation tasks.

S3 endpoint: `http://eoap-application-package-patterns-s3-seaweedfs-all-in-one:8333`, region `us-east-1`,
path addressing, credentials `test`/`test`, initialized bucket `results`.
Only the AMD64 local Kubernetes configuration has been selected for acceptance;
other architectures and storage providers need their own validation.

All 12 notebooks passed on the local AMD64 cluster with real Landsat staging
and application containers. CWL metadata/documentation and editor/S3 smoke
checks passed. Training changes are committed on `feature/pde-typed-cwl` as
`ff627a6`; this branch must be published or seeded for fresh deployments.
Run `task test:lifecycle` after notebook execution to check retained workspaces,
fresh environments and disposable S3.
