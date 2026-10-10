# PDE image adoption and SeaweedFS S3 migration

Initial findings recorded on 10 October 2026. This document records investigation
results, agreed migration scope, and remaining work. Updated after the
`mastering-app-package` AMD64 pilot on 10 October 2026. The pilot is implemented
and validated; repository-wide migration and multi-architecture acceptance
remain incomplete.

## Objective

Use the shared EOEPCA PDE development image instead of maintaining a separate
EOAP base coder image, while preserving training workflows and supporting AMD64
and ARM64 where the complete module stack permits it.

Replace the transient S3 service currently supplied by LocalStack with
SeaweedFS. Prefer a Helm-chart-based installation. This storage migration is
requested work. Chart 4.48.0 and disposable all-in-one storage have been
selected and tested for the mastering pilot; rollout to other modules and
lifecycle verification remain pending.

SeaweedFS deployment scope is decided: each module gets its own SeaweedFS Helm
release. Users run one module at a time; shared storage across modules is not
required.

Transient storage lifecycle is decided: no S3 data retention across restarts,
Skaffold shutdown, Helm uninstall, or redeployment is required. Select and verify
the Helm storage configuration against this requirement; durable S3 storage is
outside the requested scope.

S3 configuration approach is decided: provide a default SeaweedFS configuration
with initialized values and matching AWS CLI configuration for each module.
Provision the configured credentials and initialize required buckets after S3
readiness. Configure the CLI's credentials, region, endpoint, and addressing
behavior consistently with SeaweedFS. The mastering pilot verifies `test`
credentials, region `us-east-1`, path addressing, and its HTTP S3 endpoint on
port 8333. Other modules still need their own bucket and client inventories.

Existing S3 data handling is decided: discard existing LocalStack objects; no
data transfer is required. Drop LocalStack support completely in this repository,
including deployment configuration, client settings, setup instructions, and
fallback paths. This decision does not change the separate ZOO repository.

PDE multi-architecture support and the yq correction must still be verified
against the artifact selected for repository-wide adoption. The source clone is
`/data/work/github-com/eoepca/pde-code-server`. The mastering pilot uses the
locally tested `eoepca/pde-code-server:amd64`; this does not establish ARM64
support or a published manifest digest.

ZOO is low priority and has been extracted into the sibling repository
`/data/work/github.com/eoap/dev-platform-eoap-zoo`. Its image migration and
full-stack validation are deferred and do not block PDE adoption here. The coder
chart and image sources were copied there to preserve its local dependencies.

## Verified findings

### Image and deployment integration

- The shared default is `ghcr.io/eoap/dev-platform-eoap/eoap-coder:0.1.0` in
  `charts/coder/values.yaml`.
- The extracted ZOO module's `ogc-api-processes-with-zoo/skaffold.yaml` overrides that default with the local
  reference `eoap-coder:0.1.0` and declares an AMD64 build platform.
- Dask uses its own `dask-gateway-coder:0.1.0` image and separate client and worker
  images. Changing the shared chart default will not migrate Dask.
- The chart uses the coder image for both initialization and the editor container.
  It overrides the image entrypoint and launches code-server directly on port 8080.
  PDE's entrypoint-based OAuth proxy and Nextcloud sync will therefore not run
  under the current chart.
- Both source images use actual user identity 1001:100 and `HOME=/workspace`.
  PDE uses Conda Python and adds Java, GDAL, CWL tooling, isolated Calrissian,
  Skopeo, ORAS, and Trivy. These differences require runtime validation.

### Initial checks against the built PDE image

The locally available `eoepca/pde-code-server:multi-amd64` was inspected and run
in temporary containers. Its inspected image ID was
`sha256:2e83c8d10b89b5e997de1b16acc3757eceea4ae5d5fe096fa7eeb19e8a71d77b`.
This identifies the tested local artifact, not an approved production manifest.

- Architecture: AMD64; Python 3.12.11; code-server 4.138.0; Node 22.15.0.
- User identity 1001:100, writable workspace, and virtual-environment creation
  passed. Global `python -m pip check` passed.
- Required tool executables were found. GDAL reported 3.12.1.
- The chart-style direct code-server command started and its HTTP health endpoint
  responded on port 8080.
- Image size was approximately 6.24 GB uncompressed. Pull size and module startup
  time were not measured.
- `yq` resolved to `/opt/conda/bin/yq`, the Python wrapper. Mike Farah's pinned
  binary at `/usr/local/bin/yq` worked, but unqualified `yq eval` failed. The PDE
  initial failure is resolved in the later AMD64 pilot artifact: unqualified
  `yq eval` passed, `tomlq` reported its version, and isolated Calrissian
  dependency checks passed. Equivalent ARM64 checks remain pending.
- These initial container checks preceded the mastering deployment. Subsequent
  AMD64 Kubernetes, extension, package, notebook, and Podman validation passed
  using `eoepca/pde-code-server:amd64`, as recorded below. The initial image ID
  above must not be treated as the identity of that later artifact. ARM64
  runtime validation remains pending.

### Module initialization and persistent workspaces

- The mastering module now uses PDE's kubectl instead of downloading an AMD64
  binary. Architecture-specific downloads in `how-to` and
  `machine-learning-process` remain to be reviewed and removed or made aware
  of the target architecture.
- Module scripts create isolated Python environments and install module-specific
  dependencies. PDE's globally installed packages do not automatically become
  available inside those environments.
- Several modules install Calrissian independently. Executable selection and
  dependency ownership need review before those installations are removed.
- Modules install editor extensions during initialization. PDE's extension CI
  tests do not mean extensions are preinstalled in the image.
- Persistent virtual environments may need recreation when changing the base
  Python installation or CPU architecture. Preserve notebooks and user files;
  deleting workspace PVCs is not an acceptable default migration strategy.

### Calrissian and Dask

- This repo installs `Terradue/calrissian@dask-gateway` in both
  `dask-gateway/Dockerfile.coder` and `dask-gateway/files/init.sh`.
- Upstream [duke-gcb/calrissian](https://github.com/duke-gcb/calrissian) now contains
  Dask Gateway support, merged through
  [PR #214](https://github.com/duke-gcb/calrissian/pull/214) on 15 January 2026.
  The inspected upstream HEAD was `a95d87d`.
- Upstream includes `DaskGatewayRequirement`, cluster lifecycle code, Dask tests,
  `--dask-gateway-url`, and `--dask-script-configmap`.
- The initially inspected image contained Calrissian 0.18.1 without Dask
  support. The later mastering pilot uses PDE's isolated Calrissian artifact
  at `a95d87dd213d51b11faea7c6def4ced46d466a4a` (package version 0.19.0).
  Kubernetes execution passed; Dask runtime behavior remains untested.
- A custom fork is no longer required in principle. The mastering pilot uses
  the pinned upstream commit. Full equivalence to the fork and real Dask
  cluster execution have not been validated.
- Identified upstream build pin:
  `a95d87dd213d51b11faea7c6def4ced46d466a4a` (15 January 2026), the merge of
  PR #214, which includes Dask integration fixes and additional test coverage.
  Install with
  `calrissian @ git+https://github.com/duke-gcb/calrissian.git@a95d87dd213d51b11faea7c6def4ced46d466a4a`
  in PDE's isolated Calrissian environment. This commit requires
  `cwltool>=3.1.20260108082145`; recheck PDE's existing `cwl-utils==0.40` pin
  against the resolved dependencies when selecting the shared artifact.
  The mastering environment matches PDE's exact Calrissian Git provenance,
  passes dependency checks, and executes Calrissian workflows successfully.
  Dask CLI, schema, packaged resources, and cluster lifecycle validation
  remain required before replacing the Dask fork.

### Repository maintenance

- CI currently publishes the shared coder image and separate Dask images.
- CI also references missing `Dockerfile.coder` files for `advanced-tooling`,
  `application-package-patterns`, and `how-to`; adoption must account for these
  stale jobs.
- Existing CI does not validate deployment readiness or complete training flows.
- Local history showed `main` last changed on 7 January 2026 and `develop` on
  5 August 2026. They had three and nine unique commits respectively. Current
  remote branch, PR, and CI status was not established during that review.

## Decisions still pending

| Decision | Proposed direction | Evidence or approval needed |
| --- | --- | --- |
| PDE artifact to adopt | Use a published, versioned multi-platform image; pin its manifest digest | Completed PDE work, passing checks on both architectures, registry availability |
| Calrissian version | Build against identified upstream commit `a95d87dd213d51b11faea7c6def4ced46d466a4a` | Verify dependency compatibility, packaged Dask resources, and runtime behavior; decide later when to replace the commit pin with a release |
| Deployment startup | Keep the chart's direct editor command for training | Confirm whether JupyterHub authentication or Nextcloud integration is wanted here |
| Python dependency ownership | Retain module environments initially; remove redundant binary downloads | Determine which packages should be shared versus module-specific |
| Dask coder image | Assess whether PDE can replace it directly or serve as its base | Verify executable precedence, Dask dependencies, and upstream Calrissian behavior |
| ARM scope | Treat native editor support and complete module support separately | Audit Dask workers and other in-scope images; defer the ZOO stack audit |
| ZOO maintenance | Module extracted to `dev-platform-eoap-zoo`; defer PDE migration there | Decide future maintenance scope in the destination repository |
| Persistent environment migration | Rebuild only affected environments, preserving user data | Define detection, backup, and recovery procedure |
| Legacy image retirement | Retire shared coder build only after migration validation | Decide rollback period and confirm the extracted ZOO repository can build its copied coder image and review historical workflows |
| CI scope | Add useful module smoke checks and remove obsolete build references | Choose representative modules and available AMD64/ARM64 runners |
| Branch integration | Reconcile migration with existing main/develop divergence | Review remote state and select target branch |
| SeaweedFS rollout | Reuse the mastering pilot's upstream chart 4.48.0 and image 4.48 where suitable | Verify per-module resources, required S3 operations, lifecycle behavior, and architecture support |
| Default S3 configuration rollout | Pilot uses authenticated `test` credentials, `us-east-1`, HTTP port 8333, and path addressing | Verify each module's service name, buckets, clients, and any additional TLS requirements |

## SeaweedFS migration findings and work

### Confirmed current integration

- Seven modules still declare `remoteChart: localstack/localstack`:
  `dask-gateway`, `stac-eoap`, `machine-learning-process`,
  `event-driven-with-argo`, `advanced-tooling`, `application-package-patterns`,
  and `how-to`.
- Module init scripts and AWS aliases contain release-specific LocalStack
  endpoints on port 4566. Dask has additional profile-specific init scripts that
  must be included in the migration.
- `cwl-eoap` and `zarr-cloud-native-format` contain aliases to
  `eoap-cwl-localstack:4566`, but their Skaffold files do not declare a LocalStack
  release. Their intended storage integration is unresolved.
- Bucket creation commands explicitly create `results` in several modules and
  both `results` and `workflows` in `event-driven-with-argo`. This is not yet a
  complete inventory of buckets used by cloned training repositories.
- Argo's artifact repository is configured in
  `event-driven-with-argo/skaffold.yaml` with bucket `workflows`, a LocalStack
  endpoint, and secret `localstack-cred`. Its secret template and workflow
  artifact consumers must be reviewed together.
- `machine-learning-process/files/bash-rc` references the event-driven
  LocalStack endpoint despite deploying `tile-based-training-localstack`.
  Its MLflow chart configuration currently has S3 artifact storage disabled;
  enabling that storage is not an established migration requirement.
- The shared coder chart supplies AWS region `us-east-1` and credentials `test`.
  These existing values are evidence of current configuration, not a decision
  about SeaweedFS authentication.
- README setup instructions and example deployment output reference LocalStack.
  The extracted ZOO repository is outside this migration's current scope.

### Verified Helm installation source

The [upstream SeaweedFS Helm chart documentation](https://github.com/seaweedfs/seaweedfs/tree/master/k8s/charts/seaweedfs)
documents the repository and chart below:

```bash
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm install seaweedfs seaweedfs/seaweedfs --values values.yaml
```

The mastering pilot now pins chart 4.48.0 (image 4.48), enables one all-in-one
pod with authenticated S3, and uses `emptyDir` data storage. Its verified
endpoint is
`http://eoap-mastering-app-package-s3-seaweedfs-all-in-one:8333`. Readiness,
bucket initialization, and object operations passed on AMD64. Other-module
sizing, ARM64 support, and teardown/restart lifecycle behavior remain unverified.

### Implementation and validation sequence

1. Inspect and pin a chart release and its image versions for a separate
   SeaweedFS Helm release per module. Render candidate
   values to establish the actual S3 service, credentials, storage resources,
   readiness configuration, and compatibility with the target cluster.
2. Resolve the storage decisions listed above. Audit cloned module content and
   client configuration for additional buckets, endpoints, and required S3
   operations; do not infer completeness from this repository alone.
3. Pilot the Helm installation with one module. Verify readiness before bucket
   initialization and test bucket creation plus object upload, listing,
   download, and deletion using that module's actual clients.
4. Define default SeaweedFS values, initialize credentials and required buckets,
   and configure AWS CLI consistently for each module. Update module Helm
   releases, AWS aliases, initialization scripts, and endpoint configuration
   using verified service details. Resolve the two
   aliases without declared storage and the machine-learning endpoint mismatch.
5. Validate Argo artifact upload/download and the existing stage-out path;
   establish any additional S3 semantics required by actual workflows. Test
   lifecycle behavior against the agreed transient-storage policy.
6. Update setup documentation and add useful storage integration checks. Remove
   all LocalStack deployment and client configuration, setup instructions, and
   fallback paths as part of the migration. Discard existing LocalStack objects
   without transferring them; validate affected modules against SeaweedFS.

The mastering pilot completes the initial Helm/S3 compatibility pilot and
verifies its packaged stage-out path. The remaining steps cover other modules,
Argo artifacts, lifecycle tests, and repository-wide LocalStack removal. PDE
adoption and storage migration retain separate validation requirements.

## Proposed implementation sequence

1. Complete PDE multi-architecture support and targeted yq correction. Rebuild and
   test both architecture variants; verify tomlq and Python dependency health.
2. Select the upstream Calrissian version or commit and validate its Dask CLI,
   schema, and packaged controller scripts in PDE.
3. AMD64 mastering and Quickwin pilots are complete. Continue migrating simple
   modules using explicit image overrides and separate SeaweedFS releases
   before changing the shared default.
4. Remove redundant architecture-specific tool downloads from initialization;
   preserve module environments and extension installation initially.
5. Exercise editor access, extension installation, notebook kernels, S3 access,
   and a representative CWL run on each supported architecture. Test persistent
   workspace reuse and environment recreation without losing user files.
6. Validate Dask cluster creation, task execution, and teardown with upstream
   Calrissian. Then replace fork installations and decide the dedicated image's
   future.
7. Switch the shared default to the approved PDE artifact. ZOO image migration
   belongs to the extracted repository and is outside this implementation.
   Update documentation and CI, then retire redundant image sources and jobs
   according to the agreed rollback policy.

## Completion criteria

- All migrated modules reference the approved image or an intentional derivative.
- No module overrides shared tools with incompatible architecture downloads.
- Supported architectures pass agreed module checks, including notebook and CWL
  execution; Dask additionally passes cluster lifecycle checks.
- Existing user workspaces remain recoverable and user files are preserved.
- Image publication ownership, version pins, CI coverage, and unsupported module
  architectures are documented.
- Remaining decisions above are resolved or explicitly deferred with reasons.
- ZOO has been extracted; its PDE migration remains follow-up work in the new
  repository and is excluded from adoption completion criteria here.
- In-scope transient S3 services use the selected SeaweedFS Helm installation;
  endpoints and credentials are verified, and required module S3 operations and
  Argo artifact flows pass integration checks.
- Each module starts with initialized default S3 configuration and matching AWS
  CLI settings; users can access its initialized buckets without manual setup.
- Transient storage retention and cleanup behavior are documented and tested;
  existing LocalStack data is discarded without transfer.
- LocalStack support is completely removed from this repository. Historical
  findings in this plan may retain its name to explain the migration.


## Module implementation progress

### Mastering Application Package: implemented and validated on AMD64

- Uses `eoepca/pde-code-server:amd64` as an explicit module override; the shared
  coder default and other modules remain unchanged.
- Replaces LocalStack with SeaweedFS chart 4.48.0, image 4.48, one all-in-one
  pod, authenticated S3, and `emptyDir` data storage. Initializes `results`
  after a bounded readiness wait and configures matching AWS CLI defaults.
- Retains the module Python environment and installs the exact Calrissian
  artifact identified from PDE's isolated environment. Uses uv for environment
  creation, package installation, and dependency checking, and PDE's kubectl.
- Installs the Python, YAML, CWL, and Jupyter extensions plus the latest release
  VSIX assets for `eoap-validator-vscode`, `cwl-metadata-editor`, and
  `cwl-uml-viewer`.
- Checks out training branch `feature/metadata`, fast-forwarding existing
  checkouts and skipping automatic merge when local edits exist. When the
  training kernel helper exists, installs isolated Hatch
  1.16.2 with `virtualenv<21` and registers four package-specific Bash kernels.
- `task labs` runs chapters 1–4, loads their four rebuilt processing images
  into Minikube with `metadata` tags, then runs chapter 5. Kubernetes notebooks
  pack the checked-out CWL and use those local images; a new Calrissian or
  application package release is not required for this validation path.

Validation on 10 October 2026 used Docker-backed Minikube profile
`eoap-mastering-app-package-docker`. Deployment readiness, editor HTTP 200,
extension/environment initialization, and S3 upload/download cleanup passed.
All 18 notebooks passed, including Podman image builds, packaged staging tools,
typed scatter, direct Calrissian execution, the Kubernetes Job, both benchmark
executions, and usage plots/tables. The new Hatch chapter 1 notebooks also
passed on rerun, and `task code:test:all` passed all 29 package/pipeline tests.
A separate stage-out CWL roundtrip verified catalog, item, and asset objects
and asset bytes in SeaweedFS, then removed the test objects.

The training snapshot was `b5275c0` plus `ffc625f` (packaged CLI example fixes)
and `de098fb` (Otsu memory allocation), with concurrent uncommitted Hatch
notebook/environment edits copied from the host clone. Training commit
`c5c3f95` records the results. Otsu requires 1024 MiB for these inputs;
normalized difference retains 2048 MiB. Remote raster reads needed bounded
retries. Docker validation required removing an inherited DNS search suffix;
KVM validation was blocked by VM outbound connectivity.

Deployment changes are committed here as `7df4cb1` (metadata/Hatch startup),
`ba02e70` (image loading before Kubernetes labs), and `922eaa9` (validation
record). The earlier Hatch WIP was left
uncommitted during notebook validation; the remote branch subsequently
published it. Acceptance deployment updated the preserved training checkout
to `77ef29b`. Copied WIP was backed up in a Git stash before that update.
Unpublished training changes must still be copied into a deployed checkout.

Fresh rollout and workspace acceptance checks subsequently passed. The module
Python environment was recreated with the old environment retained as
`/workspace/.venv-pre-migration-backup`; a workspace sentinel survived. A
kernel check exposed Hatch interpreters stored in the init container's private
home. The shared coder chart now sets init/editor home and Hatch data/cache
paths to the workspace, and all five kernels pass in the new editor pod.
Both workspace and Calrissian PVCs now use Helm's keep policy. SeaweedFS pod
recreation and Skaffold delete/Helm uninstall followed by redeployment removed
the S3 sentinel and preserved both PVCs and the workspace file. Initialization
recreated `results`; editor and S3 smoke checks passed. Same-pod container
restarts may retain data, which is permitted by the disposable-storage policy.

Executed notebook locations and host artifact copies are recorded in
[the module README](mastering-app-package/README.md).

### Remaining acceptance checks and rollout

1. Fresh mastering rollout, workspace reuse, environment recreation, and kernel
   checks passed. Keep these checks when changing image/Python architectures.
2. Disposable S3 behavior passed for pod recreation and Skaffold delete/Helm
   uninstall followed by redeployment. A live `skaffold dev` shutdown signal
   was not separately exercised.
3. Select a published PDE artifact with a manifest digest; verify yq/tomlq,
   dependency health, and supported AMD64/ARM64 module stacks.
4. Quickwin migration and all four notebooks passed. Continue with the next
   module using explicit image overrides and the verified S3 pattern, auditing
   its cloned training content and required buckets first.
5. Validate Dask cluster lifecycle and Argo artifact flows before migrating
   those modules. Resolve undeployed-storage aliases and endpoint mismatches.
6. Update shared defaults, CI, root documentation, and remaining modules;
   remove LocalStack support and retire legacy image jobs after acceptance.

Quickwin has now also been migrated and validated on AMD64, as recorded below.
The remaining modules have not been migrated. The mastering pilot establishes an AMD64
reference implementation, not completion of the repository-wide plan.

### Quickwin: implemented and validated on AMD64

Quickwin now overrides the coder image with `eoepca/pde-code-server:amd64` and
uses its own SeaweedFS release, chart 4.48.0/image 4.48, with authenticated S3
and disposable `emptyDir` storage. Initialization uses uv with PDE Python,
preserves existing training checkouts, waits for S3, initializes `results`, and
configures matching AWS credentials, region, endpoint, and path addressing.
Module tasks cover startup, deployment, editor/S3 smoke checks, notebook
execution, development, and cluster stop. The notebook runner accepts a Python
kernel argument while retaining the mastering default.

Fresh deployment and editor/S3 checks passed on Docker-backed Minikube profile
`eoap-mastering-app-package-docker`, namespace `eoap-quickwin`, on 10 October
2026. All four notebooks passed: application, container, CWL CommandLineTool,
and CWL workflow. The tested training source was `f81b825` with a corrected
container user argument. The original hard-coded UID 1000 could not write to
PDE's UID 1001 workspace; initialization now substitutes the current UID/GID
for that argument only. The same fix was saved uncommitted in the local
Quickwin training clone and was not pushed. Artifact paths are recorded in
[the Quickwin README](quickwin/README.md).

Mastering's editor was scaled to zero while Quickwin ran on the same node;
its PVCs and training files were retained. Published multi-platform artifact
selection, ARM64 validation, Dask, Argo, other-module migration, shared-default
changes, and CI/legacy-image retirement remain outstanding.
