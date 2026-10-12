# Machine learning development module

Deploy the training repository in PDE with `task deploy KUBE_CONTEXT=<context>`.
The explicit AMD64 pilot image is `eoepca/pde-code-server:amd64`; published
multi-platform artifact selection remains pending in the platform plan.
`task start` is an optional Minikube helper. Configure storage classes for the
selected cluster. MLflow retains its current artifact-storage configuration;
this migration does not enable MLflow S3 storage.

Dedicated SeaweedFS chart 4.48.0 uses disposable storage, credentials test/test,
region us-east-1, path addressing and endpoint
http://tile-based-training-s3-seaweedfs-all-in-one:8333. Initialization creates
results after bounded readiness checks. LocalStack configuration is removed.
Workspace/output PVCs and edited source checkouts are preserved.

Publish feature/maturity-parity before fresh initialization, or explicitly seed
the retained workspace with that source. Startup never rewrites lessons. It
installs hash-locked Python 3.12 dependencies and uses PDE's isolated Calrissian.
Run `task test`, `task cwl:docs`, `task labs`, then `task test:lifecycle`.
Lifecycle checks replace disposable S3 only after workloads finish.

Development acceptance passed on 2026-10-11 in namespace tile-based-training
of the AMD64 context eoap-mastering-app-package-docker. All nine notebooks passed
together with synthetic inputs and again with 100 checksum-verified real EuroSAT
chips, using application commands, Podman and Calrissian. MLflow 3.17.0 artifact
retrieval, Keras/ONNX equivalence, source timestamps, raster grids, class values,
nodata and S3 output reads passed. Editor/S3 smoke and retained-workspace,
fresh-environment, disposable-S3 lifecycle checks passed. This is an uncommitted
source overlay, not clean published-candidate acceptance. One-epoch training does
not establish classification accuracy.

Executed evidence is retained on the editor PVC at
/workspace/lab-results/ml-final-nine and /workspace/lab-results/ml-real-nine.
S3 objects were intentionally discarded by lifecycle testing; local outputs remain.
The complete report is machine-learning-process/docs/acceptance.md in the source
checkout. The MLflow image is pinned in mlflow-values.yaml; its proxied artifact
mode is retained without enabling S3 artifact storage.

Before publication, source CWL requires processor images available in the cluster
and explicit LAB_IMAGE_TRAINING/LAB_IMAGE_INFERENCE overrides. The tested local
references were localhost/ml-training:lab and localhost/ml-inference:lab. For
published-candidate acceptance, set APPLICATION_PACKAGE_VERSION instead.

For real inputs, run task labs LOCAL_FIXTURE=0 TRAINING_INPUT=<accessible-STAC-URL>
INFERENCE_INPUT=<accessible-STAC-URL>, plus the selected release or local image
parameters. Inputs must be readable by processing pods. The host's environment
is not implicitly forwarded into Kubernetes.

Clean published-source/candidate acceptance and release verification remain
pending. ARM64 and shared PDE artifact selection remain unvalidated.
