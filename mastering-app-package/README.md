# Mastering Application Package development module

This module uses the locally tested `eoepca/pde-code-server:multi-amd64` image
and its own SeaweedFS Helm release (chart 4.48.0, image 4.48).

Add the chart repository:

```bash
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm repo update
```

Alternatively, use the module-local Taskfile (requires Task, Docker, Minikube,
Helm, kubectl, Skaffold, and the locally built PDE image):

```bash
cd mastering-app-package
task up    # Start a dedicated cluster, load the image, deploy, and smoke-test
task test  # Repeat readiness, editor HTTP, and S3 object round-trip checks
task dev   # Watch the deployment and forward editor access to localhost:8000
task stop  # Stop the dedicated cluster
```

The default profile is `eoap-mastering-app-package`, with 4 CPUs and 8192 MiB
memory. Override these with Task variables, for example
`task up MINIKUBE_PROFILE=training CPUS=6 MEMORY=12288`. Tasks select that profile
explicitly. `task up` does not keep an editor port-forward running; use `task dev`
for browser access. Smoke checks remove their temporary S3 object and do not
exercise notebook or full training workflow execution.

For the local AMD64 PDE build, load the image into Minikube before starting:

```bash
minikube image load eoepca/pde-code-server:multi-amd64
cd mastering-app-package
skaffold dev
```

A published multi-platform PDE image remains to be selected. This local tag is
for the AMD64 pilot and does not establish ARM64 module support.

Initialization installs the module's editor extensions and Python environment,
configures AWS CLI with region `us-east-1`, path-style addressing and training
credentials `test` / `test`, waits for S3 readiness, and creates `results` if
missing. The in-cluster endpoint is
`http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333`.
The terminal also supplies an AWS endpoint alias.

PDE supplies kubectl and isolated upstream Calrissian. The module environment
no longer installs its own Calrissian or downloads an AMD64 kubectl binary.
Existing workspaces may still contain those old executables; recreate only the
module virtual environment to remove them, preserving notebooks and user files.

SeaweedFS runs in one all-in-one pod with `emptyDir` storage and no storage PVC.
Objects are disposable: pod deletion/recreation or release removal loses them.
A container restart within the same pod can retain `emptyDir` contents; retention
is not guaranteed or required. Recreating only the storage pod also removes the
bucket; recreate `results` with `aws s3 mb s3://results`, or restart the coder pod
to rerun initialization. The chart keeps its credential Secret on uninstall;
that Secret contains no S3 objects.

Helm rendering/lint and AWS client configuration have been checked. Cluster
startup, extensions, notebooks, object operations, and training workflows still
require integration validation.
