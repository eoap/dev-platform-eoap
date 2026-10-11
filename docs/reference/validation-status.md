# Recorded validation and current limits

This is a snapshot of evidence recorded in the repository through **11 October 2026**. It is not a live cluster or registry report. Detailed run IDs and artifact paths are in the linked module READMEs and [PLAN.md](../../PLAN.md). Revalidate when source, artifacts, dependencies, data or target cluster change.

Recorded execution used an AMD64 Docker-backed Minikube cluster, context `eoap-mastering-app-package-docker`, with module-specific namespaces. Task defaults may use other profile names; the recorded context is not a required name for your cluster.

| Module | Recorded passing acceptance | Limits/follow-up |
| --- | --- | --- |
| [Mastering](../../mastering-app-package/README.md) | Stable `2.0.0`: 41 CI tests, six published containers, both chapter 5 notebooks on identical rc.42.1 source (direct Calrissian, Job/readability, two benchmarks), real stable-image Zarr stage-out/TiTiler reuse; chapters 1–4 passed with preceding rc.41.1 source | Exclusive full 18-notebook stable run and other architectures/clusters not established |
| [Quickwin](../../quickwin/README.md) | Four notebooks and PDE/S3 startup smoke | CWL remains v1.0/string-based; metadata, context interface, source rewriting and explicit lifecycle follow-up |
| [STAC](../../stac-eoap/README.md) | Five notebooks, six source documents/docs, invalid inputs, wrapped staging/application/output, readable georeferenced outputs, lifecycle | Required source branch publication or local seeding; retained shared OGC dependency |
| [How-to](../../how-to/README.md) | Ten standalone CWL documents/docs, eleven real Calrissian cases including custom types, strict docs, smoke and lifecycle | AMD64 accepted; HTTP/PVC workflows and separate S3 smoke; allow 8 GB for Calrissian tasks plus editor/storage |
| [CWL](../../cwl-eoap/README.md) | Three notebooks with real builds/execution, typed contract docs, smoke and lifecycle | Local feature branch availability must be resolved for fresh clones |
| [Inference](../../inference-eoap/README.md) | Six labs using local 13-band staging fixture and real ONNX model, partial-batch regression, three contracts/docs, smoke and lifecycle | Authenticated Copernicus downloading not exercised by the fixture path |
| [Patterns](../../application-package-patterns/README.md) | Stable 2.0.0: 16 real-data cases from clean `c02c778` on Minikube and release CI; 27 runner tests, 17 contracts, 12 wrappers, 26 verified public OCI packages, strict docs, smoke and earlier lifecycle | AMD64 accepted; other architectures, storage and network configurations require acceptance |
| [Dask](../../dask-gateway/README.md) | Two-worker Calrissian computation/disposal, real cloudless notebook with two satellite items, five regressions, docs, smoke and lifecycle | Full EOPF notebook blocked by remote STAC HTTP 500; matching Python 3.12 worker is local-only |
| [Contract-first](../../eoap-contract-first/README.md) | Three contracts, quality gates, 39 tests, supply-chain checks, strict docs build, actual transpiler-mate derivation, smoke and lifecycle | Registry/container publication separate; source unchanged |

## Scope boundaries

- AMD64 acceptance is established for the recorded target. ARM64 and other Kubernetes clusters need their own acceptance.
- The PDE AMD64 tag is the selected local artifact. A repository-wide approved immutable multi-platform manifest is still pending.
- Most new training changes are committed locally on feature branches. A deployment pointed at an unpublished branch is not reproducible from a fresh remote clone until published or deliberately seeded.
- Dask's worker image is built/loaded locally. Loading it into one Minikube profile does not make it available to another cluster.
- Remaining modules, shared-default changes, CI/legacy image retirement and complete LocalStack removal are unfinished plan work.
- Temporary host artifact paths in old records are evidence locations from the original session, not distributed release artifacts or durable hosting guarantees.

When collecting new evidence, use the [acceptance template](../how-to/validate-a-module.md#record-the-result), name skipped/blocked checks, and avoid presenting a partial suite as full-course acceptance.
