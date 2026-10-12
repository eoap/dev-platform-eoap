# Recorded validation and current limits

This is a snapshot of evidence recorded in the repository through **11 October 2026**. It is not a live cluster or registry report. Detailed run IDs and artifact paths are in the linked module READMEs and [PLAN.md](../../PLAN.md). Revalidate when source, artifacts, dependencies, data or target cluster change.

Recorded execution used an AMD64 Docker-backed Minikube cluster, context `eoap-mastering-app-package-docker`, with module-specific namespaces. Task defaults may use other profile names; the recorded context is not a required name for your cluster.

| Module | Recorded passing acceptance | Limits/follow-up |
| --- | --- | --- |
| [Mastering](../../mastering-app-package/README.md) | Stable `2.0.0`: 41 CI tests, six published containers, both chapter 5 notebooks on identical rc.42.1 source (direct Calrissian, Job/readability, two benchmarks), real stable-image Zarr stage-out/TiTiler reuse; chapters 1–4 passed with preceding rc.41.1 source | Exclusive full 18-notebook stable run and other architectures/clusters not established |
| [Quickwin](../../quickwin/README.md) | Four notebooks and PDE/S3 startup smoke | `a98a0c9`: all four real-data notebooks and scientific/CWL/metadata/docs checks pass clean CI; Minikube startup/S3/lifecycle pass, notebook gate blocked by truncated remote COG transfers; 2.0.0 not released |
| [STAC](../../stac-eoap/README.md) | Five notebooks, six source documents/docs, invalid inputs, wrapped staging/application/output, readable georeferenced outputs, lifecycle | Required source branch publication or local seeding; retained shared OGC dependency |
| [How-to](../../how-to/README.md) | Ten standalone CWL documents/docs, eleven real Calrissian cases including custom types, strict docs, smoke and lifecycle | AMD64 accepted; HTTP/PVC workflows and separate S3 smoke; allow 8 GB for Calrissian tasks plus editor/storage |
| [CWL](../../cwl-eoap/README.md) | Three notebooks with real builds/execution, typed contract docs, smoke and lifecycle | Local feature branch availability must be resolved for fresh clones |
| [Inference](../../inference-eoap/README.md) | Clean `39cab01`: six authenticated real Sentinel-2 notebooks, seven regressions, three contracts, locked strict docs and smoke; published `2.0.0-rc.55` workflow passed Calrissian and scientific checks on the full 10980×10980 tile | Ready for release review; stable promotion pending. CDSE S3 tested; OAuth token downloading, ARM64 and other clusters not accepted |
| [Patterns](../../application-package-patterns/README.md) | Stable 2.0.0: 16 real-data cases from clean `c02c778` on Minikube and release CI; 27 runner tests, 17 contracts, 12 wrappers, 26 verified public OCI packages, strict docs, smoke and earlier lifecycle | AMD64 accepted; other architectures, storage and network configurations require acceptance |
| [Dask](../../dask-gateway/README.md) | Clean Kind CI at `f428aed`: six regressions, locked contracts/metadata/docs, both real EO notebooks, both typed scientific CWL cases and two-worker disposal; clean Minikube acceptance; candidate artifacts/digests and anonymous pull verified | `2.0.0-rc.69` accepted; stable promotion pending; full-tile capacity and ARM64 unverified |
| [Contract-first](../../eoap-contract-first/README.md) | Three contracts, quality gates, 39 tests, supply-chain checks, strict docs build, actual transpiler-mate derivation, smoke and lifecycle | Registry/container publication separate; source unchanged |

## Scope boundaries

- AMD64 acceptance is established for the recorded target. ARM64 and other Kubernetes clusters need their own acceptance.
- The PDE AMD64 tag is the selected local artifact. A repository-wide approved immutable multi-platform manifest is still pending.
- Most new training changes are committed locally on feature branches. A deployment pointed at an unpublished branch is not reproducible from a fresh remote clone until published or deliberately seeded.
- Dask deploys the accepted public candidate worker by digest; local worker builds are optional custom-development paths.
- Remaining modules, shared-default changes, CI/legacy image retirement and complete LocalStack removal are unfinished plan work.
- Temporary host artifact paths in old records are evidence locations from the original session, not distributed release artifacts or durable hosting guarantees.

When collecting new evidence, use the [acceptance template](../how-to/validate-a-module.md#record-the-result), name skipped/blocked checks, and avoid presenting a partial suite as full-course acceptance.

## Hatch and Rocky migration, 12 October 2026

The [feature-checkout model audit](audits/module-models-progress.json) covers
18 e-learning modules, with 38 pyprojects and 41 Dockerfiles. All existing model
files pass the static checks; three Dockerfiles are classified auxiliary/service
exceptions. Five modules have no owned model files. Static alignment does not
establish notebook, processing or release acceptance.

These newer feature builds require separate acceptance from the releases above:

| Module | New model acceptance on Minikube | Remaining gates |
| --- | --- | --- |
| Machine Learning | 20 tests, nine real EuroSAT notebooks, three runtime images | Published candidate acceptance |
| Mastering | 34 leaf and 12 root tests, all six final Rocky image smoke checks | Full real notebook run blocked by slow public Sentinel-2 range transfers |
| Zarr | 80 tests, seven runtime jobs, four-date real Lake Almanor Zarr processing and source-pixel checks | Full notebooks and published candidates |
| How-To | All eleven real Calrissian cases, including custom types | Next version and published candidates |
| CWL | Two tests and all three real notebooks | Next version and published candidates |
| Patterns | 33 tests; all sixteen real wrapped cases using new runner and published Mastering staging | Next version and published candidates |
| Contract-First | 40 tests, real processing pipeline, full NDWI/Otsu pixel equality and original CRS/grid | Full notebooks and reconciliation with preserved original WIP |
| Quickwin | Five tests and real Lake Almanor processing; four notebooks pass feature CI | Fresh remote-stage notebook acceptance |
| Inline Quickwin | Six tests, real wrapped Calrissian processing and full-pixel checks | Full notebook/remote staging and license metadata discrepancy |
| Inference | Eight tests, three runtime jobs, full-scene real ONNX inference | Authenticated staging and all six notebooks with new runtime |
| Advanced Tooling | Six runtime jobs, real processing, HTTP staging and pixel/hash checks | Typed legacy workflows and full notebooks; GeoParquet still indexes acquisition items |
| Dask | Eight tests, local distributed/TLS execution | Gateway execution with new TLS 1.3 worker remains blocked |
| STAC | All five notebooks pass clean `75210b7` on Minikube and feature CI | Published candidate acceptance |

Contract-First uses an isolated feature worktree so concurrent uncommitted edits
in its original checkout remain intact. Processing-image migrations preserve
published remote CWL schema imports and never use `cwltool --pack`. The progress
report identifies the exact audited checkout and commit for each module. No
stable release promotion is part of this migration.

The supplemental platform audit also covers the Argo helpers and optional Dask
processing recipe. Argo stage-out passes six unit tests and real S3 publication
with matching EO asset hashes, original STAC geometry/time and the requested S3
prefix. Its license declaration remains pending; full Argo orchestration is not
accepted. The JSON Schema helper uses locked third-party wheels, Rocky and UID
2000, with no owned application package. Shared editors/infrastructure/services
are classified separately from processing images.
