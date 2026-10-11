# Module catalogue and learning pathways

This is a navigation guide for the deployment environments in this repository. The detailed syllabus and exercise instructions belong to each linked training repository. Choose by topic and prerequisites rather than treating the list as a mandatory curriculum.

## Learning pathways

| Starting point | Suggested sequence | What to practise |
| --- | --- | --- |
| New to application packaging | CWL EOAP → mastering → STAC | CLI/container/CWL separation, typed contracts, catalogue staging and Kubernetes execution |
| Comfortable with CWL, new to EO data | STAC → patterns → how-to | STAC inputs/outputs, reusable composition, scatter and conditional execution |
| Developing a reusable module | Contract-first → CWL contract guide → module acceptance | Schema-led interfaces, generated documentation and reproducible tests |
| Scaling an EO workload | Mastering Kubernetes exercises → Dask | Shared storage, task pods, gateway workers and distributed lifecycle |
| Model deployment | CWL EOAP → inference | Portable staged data, real ONNX execution and container/workflow packaging |

Before automated acceptance, follow the notebook's explanation manually at least once. Record the expected input/output semantics, then use the tasks to check that the complete learning sequence works.

## Migrated deployment environments

Defaults shown here come from the checked-in module Taskfiles and init scripts. A profile is the default local Minikube profile; the namespace remains separately configured in Skaffold.

| Deployment directory | Training repository | Default profile / namespace | Learning/acceptance entrypoint | Details |
| --- | --- | --- | --- | --- |
| `mastering-app-package` | [mastering-app-package](https://github.com/eoap/mastering-app-package) | `eoap-mastering-app-package` | `labs`, `labs:kubernetes` | [Module README](../../mastering-app-package/README.md) |
| `cwl-eoap` | [cwl-eoap](https://github.com/eoap/cwl-eoap) | `eoap-cwl` | Three notebooks via `labs` | [Module README](../../cwl-eoap/README.md) |
| `stac-eoap` | [stac-eoap](https://github.com/eoap/stac-eoap) | `eoap-stac` | Five notebooks via `labs` | [Module README](../../stac-eoap/README.md) |
| `how-to` | [how-to](https://github.com/eoap/how-to) | `eoap-how-to` | Ten cases via `workflows` | [Module README](../../how-to/README.md) |
| `application-package-patterns` | [application-package-patterns](https://github.com/eoap/application-package-patterns) | `eoap-application-package-patterns` | Twelve CWL patterns plus four optional-port cases via `labs` | [Module README](../../application-package-patterns/README.md) |
| `inference-eoap` | [inference-eoap](https://github.com/eoap/inference-eoap) | `eoap-inference` | Six labs plus regression tests via `labs` | [Module README](../../inference-eoap/README.md) |
| `dask-gateway` | [dask-app-package](https://github.com/eoap/dask-app-package) | `eoap-dask-gateway` | `test:dask` and selected notebooks | [Module README](../../dask-gateway/README.md) |
| `eoap-contract-first` | [eoap-contract-first](https://github.com/eoap/eoap-contract-first) | `eoap-contract-first` | Source `reference:test` via `labs` | [Module README](../../eoap-contract-first/README.md) |
| `quickwin` | [quickwin](https://github.com/eoap/quickwin) | `eoap-quickwin` | Four notebooks via `labs` | [Module README](../../quickwin/README.md); typed CWL v1.2; release-preparation feature |

Dask uses a deployment directory named `dask-gateway` but a course checkout named `dask-app-package`. How-to is a training module name, separate from this documentation's how-to section. Contract-first uses reference tasks rather than a notebook runner. These differences matter when navigating workspaces and choosing acceptance commands.

## Other repository folders

`machine-learning-process`, `event-driven-with-argo` and `advanced-tooling` remain in the migration plan. Their legacy deployment/storage paths need module-specific review; do not apply the common migrated-task sequence to them without checking their actual files. The Argo module also needs artifact-repository acceptance, not only an editor smoke test.

`zarr-cloud-native-format` deploys a PDE editor, SeaweedFS, a GeoParquet STAC API, TiTiler-EOPF 0.12.2 and an HTML viewer with S3 GeoZarr publication. See its [deployment and rendering checks](https://github.com/eoap/dev-platform-eoap/tree/feature/review-stall/zarr-cloud-native-format); the local fixture validates the actual Zarr writer, while the full remote producer workflow has separate acceptance. ZOO was extracted to a separate repository and is outside the current platform migration scope. The catalogue above describes the maintained PDE/SeaweedFS learning paths, not every historical directory as fully accepted.

See [validation status](validation-status.md) for evidence and outstanding limits.
