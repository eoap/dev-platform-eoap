# Mastering Application Package development module

This module uses the locally tested `eoepca/pde-code-server:amd64` image
and its own SeaweedFS Helm release (chart 4.48.0, image 4.48).
Initialization checks out the training repository's `feature/metadata` branch
and fast-forwards clean existing checkouts. Dirty checkouts keep their current ref and local edits
and skip automatic checkout and fast-forward.

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
task labs  # Run notebooks in order; chapter 5 uses the selected published release
task dev   # Watch an existing cluster deployment and forward access to localhost:8000
task dev:tag TAG=2.0.0  # Watch using the matching released training source and package version
task stop  # Stop the dedicated cluster
```

`task dev:tag` defaults to `APPLICATION_PACKAGE_VERSION` (`2.0.0`). Set `TAG`
to another published release, or use `task dev:tag TAG=2.0.0 KUBE_CONTEXT=my-cluster`.
The release profile passes the tag to both the init container and editor. Clean
training checkouts switch to that tag in detached HEAD mode; edited checkouts
are preserved and startup reports that the requested tag was not checked out.
The task assumes the cluster already exists, like `task dev`.

To select a training branch independently of the published application package:

```bash
task dev:ref REF=feature/fixes-for-2-0-1 APPLICATION_PACKAGE_VERSION=2.0.1
```

`REF` accepts a branch, tag, or full ref such as `refs/heads/feature/fixes-for-2-0-1`
or `refs/tags/2.0.1`. Use a full ref if branch and tag names overlap.
Initialization fetches the ref and checks it out in detached HEAD mode; dirty
checkouts retain their files and current ref. `APPLICATION_PACKAGE_VERSION`
selects the published package artifacts independently. `task dev:tag` continues
to select matching training and package releases.

The default profile is `eoap-mastering-app-package`, with 4 CPUs and 8192 MiB
memory, and the Docker driver and container runtime for Skaffold compatibility.
`task start` explicitly configures bridge CNI networking and waits for node
readiness before loading the image. Override `CNI` when using another network
plugin. If an existing profile reports `cni config uninitialized`, inspect its
`/etc/cni/net.d` configuration: restarting Minikube may leave missing CNI files
unrepaired. The resulting `not-ready` taint also blocks the storage provisioner,
so workspace PVCs can remain pending until networking is repaired.
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

Chapter 5 runs on any Kubernetes cluster configured for Calrissian. Set
`KUBE_CONTEXT` for deployment, smoke checks, notebooks, and `task dev`;
`MINIKUBE_PROFILE` is only the local cluster helper's profile and the default
context when none is supplied. `task start`, `task up`, `task stop`, and
`labs:kubernetes-images` remain optional Minikube conveniences.

To validate a published release on an existing deployment:

```bash
task labs:kubernetes KUBE_CONTEXT=my-cluster APPLICATION_PACKAGE_VERSION=2.0.0
```

The deployed training checkout must contain the release-aware chapter 5
notebooks and `scripts/prepare-kubernetes-lab.sh`. For this release, a clean
checkout can be selected explicitly without resetting local edits:

```bash
kubectl --context my-cluster -n eoap-mastering-app-package exec deployment/code-server-deployment -c code-server -- bash -euc 'cd /workspace/mastering-app-package; test -z "$(git status --porcelain)"; git fetch origin tag 2.0.0; git checkout --detach 2.0.0'
```

Initialization with `task dev:tag TAG=2.0.0` keeps the released source selected
on editor restarts. Plain `task dev` selects `feature/metadata` when the checkout
is clean; dirty checkouts preserve their current ref and edits.
Use the matching released source for candidate validation until that branch
contains the release-aware notebooks. Save local edits before switching refs.
The release-ready check prevents the chapter 5 task from silently using an old
local-image notebook. The upstream default release version is `2.0.0`; select
a published candidate explicitly when validating a forthcoming release.

The notebooks download the selected packed CWL and matching typed inputs,
validate the software version and digest-pinned registry references, and run
Calrissian directly, through a Job, and twice for benchmarks. They require no
local image builds or Minikube image loading. `task labs` also uses this published
path; the image-loading task is retained only for separate local development.

On another cluster, adjust `skaffold.yaml` for an accessible PDE runner image,
namespace, and appropriate workspace and shared RWX storage classes. Configure
Calrissian RBAC/service accounts, its `/calrissian` PVC and node selectors, and
match those names and the runner image in the training `k8s-job.yaml`. Nodes need
access to GHCR and the remote STAC data. The AMD64 PDE pilot image does not
establish support for ARM64 nodes. Selecting a context alone does not provision
these cluster-specific dependencies.

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
that Secret contains no S3 objects. The coder chart retains workspace and
Calrissian PVCs on uninstall; reinstalling the same release reuses user files.

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
Minikube. These earlier local-image tests are developer validation; the current chapter 5
path uses published release artifacts and does not load local images.

Initialization checks out `feature/metadata` and, when the kernel helper exists,
installs isolated Hatch 1.16.2 with `virtualenv<21` and registers the four Bash
kernels. This avoids the incompatible virtualenv 21 discovery API in Hatch.
Subsequent acceptance checks deployed the final script into a new pod and
verified all five kernels. The shared chart sets init/editor home and Hatch
data/cache paths to the workspace, keeping Hatch interpreters available after
init finishes. The module environment was recreated after preserving the old
`.venv` as `/workspace/.venv-pre-migration-backup`; a workspace sentinel survived.
SeaweedFS pod recreation and Skaffold delete/Helm uninstall followed by
redeployment removed the S3 sentinel while preserving workspace and Calrissian
PVCs. Initialization recreated `results` and smoke checks passed. These checks
cover pod recreation and release removal; they do not require data loss on a
container restart within the same pod.

Successful executed notebooks are saved under:

- `/workspace/lab-results/20261010T184815738179Z/` (chapters 1–4)
- `/workspace/lab-results/20261010T193433912920Z/` (Hatch chapter 1 rerun)
- `/workspace/lab-results/20261010T192341432327Z/` (chapter 5)

Host copies are `/tmp/mastering-metadata-packaged-chapters-1-4`,
`/tmp/mastering-metadata-hatch-chapter-1`, and
`/tmp/mastering-metadata-packaged-kubernetes`. The stage-out roundtrip artifacts
are in `/tmp/mastering-metadata-packaged-stage-out`.

Published candidate `2.0.0-rc.39.1` was validated on 10 October 2026 against
source tag `909a336f0a368747df2491dfaa66198e6053dd8f`, using Kubernetes v1.35.1
on AMD64 with context `eoap-mastering-app-package-docker`. Minikube supplied
the test cluster; the notebooks used GitHub release assets and GHCR pulls,
without local tool-image loading. Direct Calrissian execution, the Job, both
benchmark executions, usage plots, and report tables passed. All four processing
images were pulled successfully from GHCR by their released digests.

The downloaded CWL matched the OCI layer digest
`sha256:ecaec0c512f372434e687050c8aa56fd39444dc5b8f6628d97016bf9c979a5f0`.
The GitHub release manifest matched the manifest fetched from GHCR at
`ghcr.io/eoap/mastering-app-package/cwl/app-water-bodies-cloud-native@sha256:7d75d00cae2e5b8e5873d6694cb9c28ab5171819bf04b7203cef2c6c8e8d7398`.

The original Job completed but ran as root, producing a catalog unreadable by
the editor user. Training commit `6148e77` changes the example Job to PDE's
UID/GID 1001:100, uses a fresh `job-tmp-` prefix, and adds a catalog-readability
assertion. The Calrissian notebook was rerun successfully with that override,
using the exact same released CWL and image digests. Inspection as the editor
verified two STAC items with readable 7205 × 5768 binary `uint8` masks in
EPSG:32610. Publish and retest a new candidate to include the notebook/Job fix;
these results validate the current processing artifacts with the documented
Job configuration override. No artifacts or commits were pushed.

Successful notebook copies are `/tmp/mastering-rc39-notebooks` (original
chapter 5 execution, including both benchmarks) and
`/tmp/mastering-rc39-job-fixed` (Calrissian rerun with the readability check).
Their deployed paths are `/workspace/lab-results/20261010T204251011633Z/` and
`/workspace/lab-results/20261010T205747977662Z/`. Release manifests, image-pull
events, original/fixed Job status and logs, and a machine-readable result record
are saved in `/tmp/mastering-rc39-artifacts/`.

## Release candidate 2.0.0-rc.42.1 acceptance

[Candidate 2.0.0-rc.42.1](https://github.com/eoap/mastering-app-package/releases/tag/2.0.0-rc.42.1) includes the Zarr-aware stage-out fix merged through [PR #16](https://github.com/eoap/mastering-app-package/pull/16). CI passed 41 tests, validated CWL, built and scanned all six containers, and published verified OCI artifacts.

On the AMD64 Minikube context `eoap-mastering-app-package-docker`, both chapter 5 notebooks passed against the candidate's published artifacts: direct Calrissian execution, Kubernetes Job execution with readable outputs, and both benchmark runs with report/plot generation. Executed notebooks are retained at `/workspace/lab-results/20261011T091130190835Z`. Chapters 1–4 (16 notebooks) passed against the preceding `rc.41.1` source; that run's remaining Kubernetes tests were stopped to validate the new candidate instead. A full 18-notebook run exclusively against `rc.42.1` was not performed.

Zarr separately used the CI-published stage-out image to upload its real four-date California Sentinel-2 GeoZarr output. STAC lookup, S3 array reads, NDWI/water tiles and distinct time slices passed through TiTiler 0.12.2. The verified image is:

```text
ghcr.io/eoap/mastering-app-package/stage-out:2.0.0-rc.42.1@sha256:2f1dc2182308fd1249cfc02146bd91c8c522adff2bdeb33ed1c294e08946c5d2
```

Stage-out recursively uploads directory assets and complete enclosing Zarr v2/v3 stores, including root metadata and sibling overview groups. Nine stage-out regressions, Ruff, Bandit and mypy passed locally. Stable `2.0.0` was subsequently published and validated as described below.

## Stable 2.0.0 publication

[Release 2.0.0](https://github.com/eoap/mastering-app-package/releases/tag/2.0.0) was published on 11 October 2026 after [PR #17](https://github.com/eoap/mastering-app-package/pull/17) promoted the accepted candidate tree to main (`66ff3ea`). [Release CI](https://github.com/eoap/mastering-app-package/actions/runs/38131738350) passed 41 tests, scanned and published all six processing containers, and validated and verified three CWL/OCI packages. The source tree matches `2.0.0-rc.42.1`; notebook acceptance above applies to that source. The stable notebook suite was not rerun.

Zarr now consumes this immutable stable stage-out reference:

```text
ghcr.io/eoap/mastering-app-package/stage-out:2.0.0@sha256:2974b42df1722ebf4d220c041e4345a94553b1bb81188b545fd58c70e93f490a
```

The stable container completed a real Calrissian stage-out of the retained Northern California Sentinel-2 output. STAC bounds, S3 Zarr assets, NDWI and water-body PNG rendering, and distinct time-selected images passed through the viewer proxy.
