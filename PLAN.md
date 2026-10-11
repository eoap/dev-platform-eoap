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

## E-learning module and CWL requirements

The e-learning module source repositories are under
`/data/work/github-com/eoap`. Update their notebooks, examples, and application
packages alongside the deployment configuration when migration requires it.

- Use CWL v1.2 for all affected CWL documents.
- **DO NOT USE `cwltool --pack`.** Retain the module's existing CWL composition
  and serialization approach, including `eoap-cwlwrap` and `cwl-loader.dump_cwl`
  where applicable.
- Use typed CWL inputs and outputs, including appropriate records, enums, and
  schemas; update notebook examples and staging adapters to match those types.
- Provide metadata that validates against transpiler-mate expectations for
  `cwl2markdown`, or an equivalent documentation generator. Validate both the
  metadata and generated documentation as part of module acceptance.
- EOAP CWL documents must be standalone. Include any types they define in the
  distributed CWL document itself; publishing a separate schema file alone
  does not satisfy this requirement. Validate the final distributed document,
  including composed application packages where applicable.
- For STAC, retain the approved shared schema import
  `$import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml`.
  Embed module-defined types without replacing this shared OGC schema.
- Make changes on a feature branch in each affected repository, preserving
  existing work in progress.
- Use Conventional Commits for commits in the deployment and module repositories.

These requirements apply to remaining module work and to follow-up changes
needed to bring already migrated modules into compliance.

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

- Six modules still declare `remoteChart: localstack/localstack`:
  `dask-gateway`, `machine-learning-process`,
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
3. AMD64 mastering, Quickwin, and STAC notebook pilots are complete. Continue migrating simple
   modules using explicit image overrides and separate SeaweedFS releases
   before changing the shared default. Update their source repositories on
   feature branches to meet the e-learning and CWL requirements above, and
   rerun notebook, CWL, and documentation validation after those changes.
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
- Affected module sources use CWL v1.2 and typed inputs and outputs. Distributed
  EOAP CWL documents include their defined types and validate as standalone
  documents; metadata and documentation generation pass the selected
  transpiler-mate `cwl2markdown` or equivalent checks.
- Module and deployment changes are made on feature branches and committed
  using Conventional Commits.
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
- Earlier developer validation used locally composed CWL and Minikube-loaded
  `metadata` images. The current chapter 5 path downloads a selected published
  application package and typed inputs and uses registry images pinned by
  digest. `task labs:kubernetes` selects the release via
  `APPLICATION_PACKAGE_VERSION` and targets `KUBE_CONTEXT`; no local image
  building or loading is needed. Minikube start/load helpers remain optional.

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
4. Quickwin and STAC migration notebooks passed. Continue with the next
   module using explicit image overrides and the verified S3 pattern, auditing
   its cloned training content and required buckets first.
5. Validate Dask cluster lifecycle and Argo artifact flows before migrating
   those modules. Resolve undeployed-storage aliases and endpoint mismatches.
6. Update shared defaults, CI, root documentation, and remaining modules;
   remove LocalStack support and retire legacy image jobs after acceptance.

Quickwin has now also been migrated and validated on AMD64, as recorded below.
STAC migration is also implemented, as recorded below. How-to, CWL, inference, Dask and application-package-patterns work is recorded
below; remaining modules still need migration. The mastering pilot establishes an AMD64
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

### Quickwin review against the current requirements

Review on 11 October 2026 confirms the AMD64 PDE/SeaweedFS deployment work,
uv environment, bounded S3 readiness, and earlier four-notebook validation.
It does not meet the later source requirements yet:

- Both training CWL documents still declare v1.0 and use string parameters for
  URI/AOI/band/CRS values; migrate to v1.2 and appropriate CWL records/enums.
- Metadata/documentation-generation acceptance is not configured.
- The training checkout is on `main` with the earlier UID fix uncommitted;
  preserve it and move follow-up changes to a feature branch with Conventional
  Commits.
- Startup rewrites the container notebook. Move that fix into the training
  source and select a compatible training ref instead of editing notebooks
  during initialization.
- Deployment tasks use `MINIKUBE_PROFILE` directly and `dev` starts Minikube;
  separate `KUBE_CONTEXT` and optional local-cluster helpers as in STAC/how-to.
- Workspace/environment recreation and disposable S3 lifecycle checks still
  need explicit Quickwin evidence.

The review leaves the existing Quickwin WIP intact. These are follow-up items;
the earlier migration validation is not acceptance of the new CWL requirements.

### Published chapter 5 candidate validation

Release `2.0.0-rc.39.1`, source `909a336`, was tested on 10 October 2026 using
Kubernetes v1.35.1/AMD64 on the available Minikube-backed cluster. Chapter 5
used the published packed CWL, typed scatter inputs, and four digest-pinned
GHCR processing images. No local image loading was used for this validation.
GitHub and GHCR OCI manifests matched, and the downloaded CWL matched its
published layer digest. Direct Calrissian execution, the Kubernetes Job, both
benchmarks, and notebook plots/tables passed.

Post-run inspection exposed an example Job defect: root execution produced
editor-unreadable output directories. Training commit `6148e77` aligns the Job
with PDE UID/GID 1001:100, separates its temporary prefix, and asserts catalog
readability. The Calrissian notebook passed again with that runtime override
and the unchanged candidate CWL/images. Two STAC items and their 7205 × 5768
binary masks were readable and georeferenced in EPSG:32610. A fresh candidate
and another candidate test are required to include this source fix in the
release; the current processing artifacts passed with the documented override.

Deployment, smoke tests, notebook tasks, and development watching now accept
`KUBE_CONTEXT` independently of local Minikube helpers. Chapter 5 and the full
lab task use published artifacts via `APPLICATION_PACKAGE_VERSION`; local
image loading is optional developer work. Cluster-specific runner images,
namespaces, RBAC, RWX storage, user/group IDs, and node selectors must be
configured for the target Kubernetes cluster. Only the available AMD64 cluster
was exercised; this does not establish ARM64 or other-cluster runtime results.
A dirty training checkout retains its ref and edits during initialization,
including the patched candidate checkout. Evidence paths and exact digests are
recorded in [the mastering module README](mastering-app-package/README.md).


### STAC: typed training workflows and AMD64 migration

The initial requirements audit found external module-defined types and missing
metadata/documentation checks. The follow-up fixes embed EPSG and band enums
in the application CWL and URI definitions in staging CWL. The shared OGC
schema import is explicitly retained at the user's request:
`$import: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml`.
Module-defined types must be included in their document; this approved shared
schema remains an external dependency.

The application metadata now identifies the STAC repository and its declared
author. A module-local Markdown generator validates metadata, documented typed
ports, and embedded definitions; it allows the approved OGC import and rejects
other imports/includes. `task cwl:docs` also validates isolated copies with
network fetching restricted to that OGC schema. This is the equivalent
documentation-generation path; transpiler-mate compatibility is not claimed.

Composition uses `eoap-cwlwrap` and serialization uses `cwl-loader.dump_cwl`.
The wrapping notebook embeds the URI definition introduced by the wrapper
while preserving OGC imports. **Do not use `cwltool --pack`.**

Training commit `c933015` implements these fixes on `feature/typed-cwl-inputs`.
Validation completed on 11 October 2026: all six source CWL documents passed
metadata/Markdown generation and isolated validation with only the approved
OGC schema fetch allowed. Notebooks 01–03 passed in UTC run
`20261010T215727173440Z`; the final 04–05 run passed in
`20261010T220833487865Z`. The final composed workflow passed and returned
`s3://results/run-005/catalog.json`, with evidence in
`/workspace/stac-final-run.log` and `/workspace/stac-final-result.json`.
The new training commit still needs publishing before fresh clones can use it.

STAC now uses an explicit PDE AMD64 image override, a separate disposable
SeaweedFS 4.48.0 release, and cluster-aware deployment/smoke/notebook tasks.
The runner supports a configurable notebook directory and selects the module
kernel for Python notebooks while retaining Bash kernels. Startup uses uv,
initializes `results`, preserves a dirty training checkout, and selects
`feature/typed-cwl-inputs`. Training fixes live in that repository rather than
being rewritten during startup.

Training commit `7e8fe5e` on `feature/typed-cwl-inputs` introduces CWL 1.2,
URI records for references/endpoints/results, an OGC BBox AOI, EPSG and band
enums, and examples for both processing and wrapped workflows. It uses
EOEPCA's `eoap-cwlwrap==0.32.0` Python API and `cwl-loader==0.27.0`. It also
corrects missing notebook dependencies, Click failure assertions, cwltool
argument defaults, explicit staging network access, serial bounded downloads,
and uploaded STAC root links.

All five notebooks passed on Kubernetes v1.35.1/AMD64. The composed typed
stage-in/application/stage-out workflow passed end to end. CWL validation and
invalid-input rejection checks passed; S3 catalogs/items/root links resolved
and all three output paths held readable 1832 × 2359 binary masks in
EPSG:32611. Evidence is recorded in [the STAC README](stac-eoap/README.md).
The training branch is committed locally and must be published before fresh
clones can use it. ARM64, other-cluster execution, Dask, Argo, shared defaults,
CI, and the six remaining storage releases still require work.


STAC lifecycle checks also passed: S3 pod recreation discarded stored objects;
workspace files survived, the old environment was retained as a backup, and
redeployment recreated the bucket and a compatible Python environment. Training commit `d9c92ec` declares the PyYAML dependency exposed by environment
recreation. The wrapping notebook passed again with the corrected environment. Mastering's editor was
scaled down during STAC validation; its workspace PVC remains retained.

### How-to: implemented and validated on AMD64, 11 October 2026

The deployment now uses PDE, upstream container Calrissian, uv, a retained
workspace and its own disposable authenticated SeaweedFS. All nine standalone
CWL v1.2 documents include URI/JSON records and band/CRS enums, described ports
and repository/version/license/author metadata. The equivalent Markdown
generator validates each document from an isolated copy.

All ten real Calrissian workflow cases passed. Reprojection uses the CWL enum
value `EPSG4326` and translates it to rasterio's `EPSG:4326`. Raster steps need
2 GiB and color processing 4 GiB; the test-suite resource budget is 8 GB.
Editor HTTP and S3 roundtrip passed. Restart acceptance preserved a workspace
sentinel and the previous environment, created a fresh environment, discarded
the previous S3 object and initialized `results`. Training commit `369cd7d`
on `feature/pde-typed-cwl` records the source migration. Evidence paths are in
[how-to/README.md](how-to/README.md).

### CWL EOAP: implemented and validated on AMD64, 11 October 2026

Uses PDE and dedicated SeaweedFS with cluster-context tasks. The source package
uses CWL v1.2, an embedded URI record and a captured File output for raster
bounds, with validated metadata and generated Markdown. Notebook jobs use URI
records; container examples use the runtime UID/GID and install libexpat.
All three real notebooks passed, including builds and CWL execution. Editor/S3
checks and fresh-environment/workspace-retention/disposable-S3 lifecycle passed.
Training commit `da43124` on `feature/pde-typed-cwl` records the changes.

### Inference EOAP: implemented and validated on AMD64, 11 October 2026

New deployment folder `inference-eoap` uses PDE and dedicated SeaweedFS. All
three CWL documents are v1.2 with embedded URI schemas, described ports and
validated metadata/Markdown. All six notebooks passed using the user-selected
local 13-band STAC staging fixture and the actual ONNX model through Python,
Podman, CommandLineTool and workflow paths. The fixture uses portable relative
asset paths. The inference loop previously dropped the final partial batch;
that is fixed and the focused regression passed. Authenticated Copernicus
downloading remains a separate validation path; no credentials were supplied.
Editor/S3 and workspace/environment/disposable-S3 lifecycle checks passed.
Training commit `c5408c3` on `feature/pde-typed-cwl` records the source changes.

### Dask Application Package: deployment implemented; full notebook acceptance in progress

The existing `dask-gateway` folder deploys this course. It now uses PDE's
upstream Calrissian, Dask Gateway 2025.4.0 matching the course protocol version,
and its own SeaweedFS. All editor profiles share the same setup. The typed
source uses the upstream `clusterMaxCores` spelling and embedded URI/Date/BBox/
SpectralBand types with validated metadata and Markdown. The original
one-step application adapters are exposed directly as CommandLineTools with
the same interface to avoid the pinned runtime's nested custom-requirement
validation failure. The Dask requirement remains mandatory.

A bounded real Calrissian test passed: two workers computed a sum of squares
of 328350 and the cluster was shut down. Editor/S3 and environment/workspace/
disposable-S3 lifecycle checks passed. The published course images use Python
3.10 while PDE uses Python 3.12, causing notebook task deserialization failure.
A matching Python 3.12 worker with both course packages and one shared runtime
dependency lock was built and loaded. The real cloudless notebook passed with
two satellite items. Five regressions passed, covering nonzero CLI failures and
current/legacy projection metadata. The EOPF notebook remains unvalidated:
its remote STAC item endpoint returns HTTP 500 on repeated attempts. Worker
artifact publication and architecture scope remain to be verified. Training
commit: `2a336b8` on `feature/pde-typed-cwl`.

### Application Package Patterns: deployment implemented; notebook acceptance in progress

PDE, current eoap-cwlwrap/cwl-loader APIs and dedicated SeaweedFS are deployed.
All 18 nonempty source/composed CWL documents validate as standalone v1.2
packages with described metadata/ports and embedded module types; the existing
shared OGC/GeoJSON schemas remain explicit imports. Wrapping uses eoap-cwlwrap
and dump_cwl, then embeds the wrapper-introduced URI definition. No packing
command is used. Diagram generation uses local Graphviz and PlantUML source,
avoiding the external image server that returned HTTP 403. Ordinary Graphviz
boxes resolve the record-node flat-edge rendering failure. All 12 notebooks
passed real Landsat staging and application container execution, including
S3 output cases. Bounded staging retries recover interrupted remote transfers
and still fail after the last attempt. Training commit: `ff627a6` on
`feature/pde-typed-cwl`. Editor/S3 smoke and retained-workspace/fresh-environment/disposable-S3
lifecycle acceptance passed.

### Contract-first: new deployment implemented and validated on AMD64

The new `eoap-contract-first` folder deploys the existing sibling course using
PDE, its locked uv tooling and dedicated SeaweedFS. Its source already meets
the contract-first CWL requirements and was not modified. The `reference:test`
gate passed: all three contract entrypoints, formatter, lint, strict typing,
security, all 39 tests, supply-chain inventory/tests and strict documentation
build. Real transpiler-mate artifact derivation including cwl2markdown passed.
The task wrapper clears inherited Podman options so explicit no-container
reference tests execute. Editor/S3 and retained-workspace/fresh-environment/
disposable-S3 lifecycle passed. Supply-chain registry publication and container
release tasks remain separate explicitly gated operations.

### Shared acceptance and remaining rollout

`task test:lifecycle` uses `scripts/test-module-lifecycle.sh` to recreate the
environment while retaining a backup and the workspace PVC, restart disposable
S3, and verify a fresh results bucket. Run it after workload tests finish.
The tested deployment is the AMD64 Docker-backed local Kubernetes context
`eoap-mastering-app-package-docker`; task `KUBE_CONTEXT` support does not
establish acceptance on other clusters or ARM64. Feature commits have not been
pushed; publish the training branches or seed their checkouts before fresh
initialization selects them.

Other pending work includes Quickwin's newly recorded CWL/type/metadata gaps,
machine-learning-process, event-driven-with-argo artifact flow, advanced-tooling,
undeclared-storage aliases, shared image/digest/ARM approval, legacy CI/image
retirement and remaining root documentation cleanup.

### Zarr: editor, TiTiler server and client deployed and validated on AMD64

`zarr-cloud-native-format` now builds the sibling `feature/zarr-conventions`
checkout's pinned compatible TiTiler derivative and deploys separate server and
client services beside the PDE editor. Read-only shared mounts expose completed
catalogs through atomic publication at `titiler-data`. The client uses a
same-origin API proxy, published STAC metadata and server-advertised variable
paths. The current upstream TiTiler main branch targets a STAC API; the local-store
reader is pinned by digest with guarded GeoZarr/time fixes.

Editor/server/client/proxy readiness and actual module-produced GeoZarr rendering
passed on `eoap-mastering-app-package-docker`, including overviews, nonempty PNG
pixels, public TileJSON URLs and distinct time slices. A reproducible local-input
fixture task exercises the module writer and GeoZarr validation without remote EO
product downloads. Full remote producer notebooks and other clusters/architectures
remain separate acceptance. This module uses shared files rather than an S3 alias.

### Zarr S3 / TiTiler 0.12.2 integration

SeaweedFS now supplies this module's local S3 service. The Zarr feature checkout
adds an eoap-cwlwrap composition for the final producer catalog, item-mode STAC
publication, full-store asset URLs and group-based multiscale layout entries.
The mastering `feature/zarr-stage-out` branch extends stage-out for recursive
assets and enclosing Zarr stores, and fixes temporary-root STAC links.

The development platform runs the unmodified upstream TiTiler 0.12.2 image,
pinned by digest, and a database-free stac-fastapi-geoparquet service. Metadata
indexes are uploaded with the S3 catalog and mirrored on the workspace PVC for
API queries. TiTiler resolves STAC assets through the API and reads arrays directly
from SeaweedFS. Actual wrapped stage-out pods, S3 publication, GeoParquet lookup,
NDWI/water-body tiles and distinct time slices passed on the local AMD64 context.
The complete real-data producer subsequently passed with four Microsoft Planetary
Computer Sentinel-2 L2A acquisitions over the Northern California lake area
(June 3, 8, 13 and 18, 2021). Calrissian produced both GeoZarr and EOPF outputs.
Real full-resolution processing required increasing the tools' 512 MiB memory
limits to 2 GiB. The GeoZarr result was staged to S3 and activated as `water-bodies`;
its bounds `[-121.399054, 39.823361, -120.739953, 40.482799]`, nonempty NDWI/water
tiles and distinct time slices passed through the client proxy. Run artifacts are
retained at `/calrissian/real-us-lake`; `task test:producer:real` repeats processing
and publication with timestamped run directories. Synthetic service checks now
use the separate `viewer-smoke-fixture` collection and cannot replace this EO
output. Producer notebook execution and other clusters/architectures remain
separate checks. Disposable SeaweedFS replacement requires bucket recreation and
republication of outputs.

### Mastering rc.42.1: released stage-out accepted for Zarr reuse

The Zarr directory-asset blocker is fixed in mastering develop via PR #16.
Release CI run 38126039457 published `2.0.0-rc.42.1` from commit `270a632`:
41 tests, CWL checks, six container builds/scans, and verified OCI publication
passed. Stage-out supports complete Zarr v2/v3 stores, subgroup assets, and
normalized STAC roots; nine local regressions plus lint/security/typing passed.

Both chapter 5 notebooks passed against the new candidate's published artifacts
on the AMD64 Docker-backed Minikube context, including direct Calrissian,
Kubernetes Job/readability and two benchmark/report executions. Evidence is at
`/workspace/lab-results/20261011T091130190835Z`. Sixteen earlier notebooks passed
with rc.41.1 source; its remaining Kubernetes run was superseded, so do not claim
an exclusive full 18-notebook rc.42.1 run.

The published stage-out image also staged the real California Sentinel-2
GeoZarr output through Calrissian; S3/STAC lookup and TiTiler 0.12.2 NDWI/water
rendering and distinct time slices passed. Zarr now uses that GHCR image pinned
by digest instead of building the sibling mastering checkout. Its viewer is
included in the platform checkout. The remaining Zarr training-source overlay
still needs removal for standalone platform deployment acceptance.

Temporary in-place storage CPU reservation reductions were restored after
validation, without storage pod restarts. Stable 2.0.0 remains unpublished;
promote the accepted source through stable CI, then update downstream digest pins.

### Mastering stable 2.0.0 published

On 11 October 2026, PR #17 promoted the validated candidate tree to main
(`66ff3ea`). Release CI run 38131738350 passed all 41 tests, scanned and
published six GHCR processing images, verified three CWL/OCI packages, and
published the non-prerelease GitHub tag `2.0.0`. Main's source tree matches
`2.0.0-rc.42.1`; the prior notebook evidence remains applicable without claiming
a new full stable notebook run.

The Zarr chart and live publication settings now use the stable stage-out
image pinned to `sha256:2974b42df1722ebf4d220c041e4345a94553b1bb81188b545fd58c70e93f490a`.
A real Calrissian stage-out of the retained Northern California Sentinel-2
output passed, followed by S3/STAC bounds and asset checks, NDWI and water
rendering, and distinct time-selected PNGs through TiTiler-EOPF. This completes
the mastering stable publication and Zarr stage-out image reuse gate. The
Zarr training-source overlay dependency remains a separate pending item.

### Zarr release-aware lab preparation

The feature checkout now accepts `APPLICATION_PACKAGE_VERSION` throughout its
practice labs. A shared preparation script downloads matching producer, S3 wrapper,
consumer and collection-mode input assets into a versioned runtime directory.
It checks CWL v1.2, release metadata, public entrypoints and immutable GHCR images
before replacing prepared files. Current notebooks no longer download 0.5.0 or
pull a mutable latest consumer. Seven rejection/acceptance regressions passed;
all nine notebook structures and Bash cell syntax validate, and MkDocs builds.
Platform deployment no longer overlays a sibling checkout.

### Zarr rc.80.1: Minikube notebook acceptance

Candidate `2.0.0-rc.80.1` (source `b782d08`, CI run `38134949070`, attempt 2)
published all seven processor images and the three matching CWL/OCI packages.
On 2026-10-11, all nine practice notebooks were attempted on Minikube using
those published artifacts and Calrissian. The six component notebooks and the
full producer passed with real EO observations. Two release blockers remain:

- Exploitation reads `cube:dimensions` from the wrong STAC object and raises
  `RequiredPropertyMissing` after successfully opening the produced data.
- The released occurrence container lacks registration of the rioxarray accessor
  and raises `AttributeError: 'DataArray' object has no attribute 'rio'`.

The editor also lacked `nest_asyncio`; the platform initialization now installs
it, and the repaired environment passes `uv pip check`. Executed notebooks remain
on the editor PVC under `/workspace/zarr-notebook-acceptance/`, in runs
`20261011T112929547132Z`, `20261011T114404006696Z` (exploitation retry), and
`20261011T114338546278Z` (consumer). Acceptance is **7/9 passed**; a corrected
candidate and execution of the failing notebooks are required before promotion.
The seven approved Trivy exceptions apply only to candidate testing; stable CI
clears them and retains its vulnerability gate.

### Zarr rc.81.1: full notebook acceptance passed

Feature commit `7e6f58d` fixes the occurrence processor's missing rioxarray
accessor registration and updates exploitation to use the measurement asset's
cube metadata, variables, Zarr group, and projection when exporting a GeoTIFF.
An occurrence regression verifies raster export, CRS, transform, and values and
is included in scoped CI tests. Platform commit `98ed256` installs nest-asyncio.

[Candidate 2.0.0-rc.81.1](https://github.com/eoap/zarr-cloud-native-format/releases/tag/2.0.0-rc.81.1)
published successfully in [CI run 38137099764](https://github.com/eoap/zarr-cloud-native-format/actions/runs/38137099764).
All **nine practice notebooks passed together** on 2026-10-11 using Calrissian on
Minikube, the exact published source tag, matching release CWL, and immutable
published images. This includes real EO processing of four Sentinel-2
observations, exploitation, and the occurrence consumer. Executed notebooks are
retained on the editor PVC at
`/workspace/zarr-notebook-acceptance/20261011T120215449598Z`.

This closes the rc.80.1 notebook blockers. It does not waive the stable security
gate: approved exceptions remain candidate-only, and EOPF dependency findings
must be resolved or separately approved before stable publication.
