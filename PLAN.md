# PDE image adoption and SeaweedFS S3 migration

Initial findings recorded on 10 October 2026. This document records investigation
results and proposed work; migration decisions have not yet been approved.

## Objective

Use the shared EOEPCA PDE development image instead of maintaining a separate
EOAP base coder image, while preserving training workflows and supporting AMD64
and ARM64 where the complete module stack permits it.

Replace the transient S3 service currently supplied by LocalStack with
SeaweedFS. Prefer a Helm-chart-based installation. This storage migration is
requested work; exact chart versions, deployment values, and lifecycle policy
remain to be determined from evidence rather than assumed.

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
behavior consistently with SeaweedFS. Exact values and chart configuration keys
must be verified before implementation; none are selected by this decision.

Existing S3 data handling is decided: discard existing LocalStack objects; no
data transfer is required. Drop LocalStack support completely in this repository,
including deployment configuration, client settings, setup instructions, and
fallback paths. This decision does not change the separate ZOO repository.

The PDE multi-architecture implementation and yq correction are ongoing in
`/data/work/github.com/eoepca/pde-code-server`. Their completion and validation
remain prerequisites for adoption here.

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

### Checks against the built PDE image

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
  correction must be verified against a rebuilt image.
- No Kubernetes deployment, module package installation, editor extension test,
  notebook execution, Podman execution, or ARM64 runtime test was performed here.

### Module initialization and persistent workspaces

- `mastering-app-package`, `how-to`, and `machine-learning-process` download
  AMD64-specific tools into module virtual environments. These can shadow PDE's
  architecture-correct tools and must be removed or made architecture-aware.
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
- The tested PDE image installs Calrissian 0.18.1. It has no `calrissian.dask`
  module and exposes no Dask CLI options.
- A custom fork is no longer required in principle. PDE must first use an
  upstream release containing the merge, or a pinned upstream commit. Full
  equivalence to the fork and real cluster execution have not been validated.
- Identified upstream build pin:
  `a95d87dd213d51b11faea7c6def4ced46d466a4a` (15 January 2026), the merge of
  PR #214, which includes Dask integration fixes and additional test coverage.
  Install with
  `calrissian @ git+https://github.com/duke-gcb/calrissian.git@a95d87dd213d51b11faea7c6def4ced46d466a4a`
  in PDE's isolated Calrissian environment. This commit requires
  `cwltool>=3.1.20260108082145`; recheck PDE's existing `cwl-utils==0.40` pin
  against the resolved dependencies. Image builds and Dask runtime validation
  against this pin remain pending.

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
| SeaweedFS chart and image pins | Prefer the upstream Helm chart | Inspect a selected chart release, its values and templates, and image manifests before selecting versions |
| Default S3 configuration values | Provide initialized SeaweedFS defaults and matching AWS CLI configuration per module | Verify credential provisioning, rendered service addresses, region, addressing style, and TLS settings before selecting exact values |

## SeaweedFS migration findings and work

### Confirmed current integration

- Nine modules declare `remoteChart: localstack/localstack`: `mastering-app-package`,
  `dask-gateway`, `stac-eoap`, `machine-learning-process`, `quickwin`,
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

This establishes a Helm installation source, not validated deployment values for
this project. No chart release, S3 service name or port, topology, persistence
mode, resource sizing, or architecture support has been selected or tested.

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

No SeaweedFS deployment or S3 compatibility test has been run as part of these
initial findings. PDE adoption and storage migration are separate changes with
separate validation requirements.

## Proposed implementation sequence

1. Complete PDE multi-architecture support and targeted yq correction. Rebuild and
   test both architecture variants; verify tomlq and Python dependency health.
2. Select the upstream Calrissian version or commit and validate its Dask CLI,
   schema, and packaged controller scripts in PDE.
3. Pilot a simple module such as `quickwin`, using explicit
   image overrides before changing the shared default.
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

Work proceeds one module at a time, starting with `mastering-app-package`.
Its configuration now overrides the coder image with the tested local PDE
AMD64 tag and replaces LocalStack with SeaweedFS chart 4.48.0, using one
all-in-one pod and emptyDir storage. Initialization configures AWS CLI, waits
for S3, and creates `results`; duplicate Calrissian installation and the AMD64
kubectl download are removed. Helm lint/rendering and AWS default endpoint
resolution pass. Full module integration validation remains pending. Other
modules have not been migrated. See the module README for local-image setup,
existing-environment handling, and disposable-storage behavior.
