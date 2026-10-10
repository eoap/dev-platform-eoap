# Mastering Application Package development module

This module uses the locally tested `eoepca/pde-code-server:amd64` image
and its own SeaweedFS Helm release (chart 4.48.0, image 4.48).
Initialization checks out the training repository's `feature/metadata` branch
and fast-forwards existing checkouts without resetting local changes.

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
task labs  # Run chapters 1–4, load their rebuilt images, then run chapter 5
task dev   # Watch the deployment and forward editor access to localhost:8000
task stop  # Stop the dedicated cluster
```

The default profile is `eoap-mastering-app-package`, with 4 CPUs and 8192 MiB
memory, and the Docker driver and container runtime for Skaffold compatibility.
Override these with Task variables, for example
`task up MINIKUBE_PROFILE=training CPUS=6 MEMORY=12288`. Tasks select that profile
explicitly. `task up` does not keep an editor port-forward running; use `task dev`
for browser access. Smoke checks remove their temporary S3 object and do not
exercise notebook or full training workflow execution.

After deployment, run `task labs:list` to inspect the notebook order, or select
a chapter with `task labs LAB=1-Application_Steps`. A relative notebook path or
quoted glob also works, for example
`task labs LAB='1-Application_Steps/crop.ipynb' CELL_TIMEOUT=3600`.
For the existing validation cluster, add
`MINIKUBE_PROFILE=eoap-mastering-app-package-docker` to these commands.
The runner uses PDE's notebook execution tools and Bash kernel; Python notebooks
use the module's `mastering_env` kernel. It stops on a reported execution error
and saves executed notebooks, including failed-cell output, under a unique
`/workspace/lab-results/` directory without overwriting source notebooks.
The default timeout is 1800 seconds per cell. Run dependent notebooks in order:
later notebooks consume files and container images produced by earlier labs.
The labs execute their original commands, including clearing training `runs`
directories, downloading data, building containers, and launching Kubernetes
jobs. The module kernel includes Calrissian installed from the same Git commit
or package version as PDE's isolated environment. `task labs` is separate from `task up` and the
deployment smoke checks.

The full `task labs` (or `task labs:all`) run loads chapter 2's rebuilt tool
images into Minikube before chapter 5. For selected chapter runs, perform these
steps explicitly:

```bash
task labs LAB='[1-4]*' MINIKUBE_PROFILE=eoap-mastering-app-package-docker
task labs:kubernetes-images MINIKUBE_PROFILE=eoap-mastering-app-package-docker
task labs LAB=5-Kubernetes MINIKUBE_PROFILE=eoap-mastering-app-package-docker
```

The image-loading task tags all four tool images with `metadata` and loads
them into the node. The updated Kubernetes notebooks pack the checked-out CWL
and use those images, so validation does not need a new published release.
Local fixes in the training clone must also be copied into the deployed
checkout while they remain unpublished.

For the local AMD64 PDE build, load the image into Minikube before starting:

```bash
minikube image load eoepca/pde-code-server:amd64
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

PDE supplies kubectl and isolated upstream Calrissian. Initialization also
installs matching Calrissian in the module environment for notebook imports,
using the container package's provenance to select the exact Git commit or
version. It does not download an AMD64 kubectl binary. Initialization installs
the latest released VSIX assets for `eoap-validator-vscode`,
`cwl-metadata-editor`, and `cwl-uml-viewer` from their GitHub release APIs.

SeaweedFS runs in one all-in-one pod with `emptyDir` storage and no storage PVC.
Objects are disposable: pod deletion/recreation or release removal loses them.
A container restart within the same pod can retain `emptyDir` contents; retention
is not guaranteed or required. Recreating only the storage pod also removes the
bucket; recreate `results` with `aws s3 mb s3://results`, or restart the coder pod
to rerun initialization. The chart keeps its credential Secret on uninstall;
that Secret contains no S3 objects.

Integration validation passed on 10 October 2026 using
`eoepca/pde-code-server:amd64` on the Docker-backed Minikube profile
`eoap-mastering-app-package-docker`. Cluster startup and image loading completed;
`task deploy MINIKUBE_PROFILE=eoap-mastering-app-package-docker` and
`task test MINIKUBE_PROFILE=eoap-mastering-app-package-docker` passed. Both
deployments became ready, editor initialization installed the extensions and
Python environment, the editor health endpoint returned HTTP 200, and an S3
object upload/download matched its original content and was deleted afterward.
The validation node's inherited DNS search suffix was removed to work around
the home router resolving external names to loopback. KVM validation was blocked
by VM outbound connectivity.

Practice notebook validation of `feature/metadata` passed on 10 October 2026
on profile `eoap-mastering-app-package-docker`: all 18 notebooks passed,
including the packaged tools and staging images, typed scatter workflow,
direct Calrissian run, Kubernetes Job, both benchmark executions, and report
plots and tables. Chapter 1 was rerun successfully with the concurrent Hatch
notebook edits. `task code:test:all` passed all 29 package and pipeline tests.
A separate stage-out CWL roundtrip verified three objects and asset bytes in
SeaweedFS and removed its test objects.

The tested source was `b5275c0` with fixes committed as `ffc625f` (packaged CLI
examples) and `de098fb` (Otsu memory), plus the uncommitted Hatch environment,
kernel helper, Taskfile, and chapter 1 notebook edits copied from the host.
The Hatch WIP remains uncommitted. Otsu requires 1024 MiB with these packaged
tools; normalized difference retains 2048 MiB. Remote raster reads still need
bounded retries. No Calrissian or application package release is needed:
chapter 5 packs the local workflow and uses the rebuilt images loaded into
Minikube. The full `task labs` sequence loads those images automatically.

Initialization checks out `feature/metadata` and, when the kernel helper exists,
installs isolated Hatch 1.16.2 with `virtualenv<21` and registers the four Bash
kernels. This avoids the incompatible virtualenv 21 discovery API in Hatch.
The updated initialization segment and notebook environments were exercised
in the existing editor; a fresh deployment rollout was not performed.

Successful executed notebooks are saved under:

- `/workspace/lab-results/20261010T184815738179Z/` (chapters 1–4)
- `/workspace/lab-results/20261010T193433912920Z/` (Hatch chapter 1 rerun)
- `/workspace/lab-results/20261010T192341432327Z/` (chapter 5)

Host copies are `/tmp/mastering-metadata-packaged-chapters-1-4`,
`/tmp/mastering-metadata-hatch-chapter-1`, and
`/tmp/mastering-metadata-packaged-kubernetes`. The stage-out roundtrip artifacts
are in `/tmp/mastering-metadata-packaged-stage-out`.
