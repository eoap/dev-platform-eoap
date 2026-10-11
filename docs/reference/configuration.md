# Configuration and filesystem reference

The configuration files are the source of truth. The tables describe the current migrated deployment pattern; inspect the module before applying an override.

## Files and responsibilities

| File | Responsibility |
| --- | --- |
| `<module>/Taskfile.yaml` | Host commands, context/profile selection and acceptance wrappers |
| `<module>/skaffold.yaml` | Helm releases, namespaces, image/resource overrides and editor port-forward |
| `<module>/coder-values.yaml` when present | Additional coder/Calrissian/security settings |
| `<module>/seaweedfs-values.yaml` | Dedicated authenticated disposable S3 deployment |
| `<module>/files/init.sh` | Source selection, dependencies, extensions, kernels and bucket readiness |
| `<module>/files/bash-rc`, `bash-login` | Editor terminal environment and aliases |
| `charts/coder` | Shared editor, init, service, PVC and Calrissian RBAC templates |
| `scripts/test-module-lifecycle.sh` | Environment backup/recreation and disposable-S3 test |

The shared coder image default is still the legacy `ghcr.io/eoap/dev-platform-eoap/eoap-coder:0.1.0`. Migrated modules explicitly override it to PDE; editing the default is separate unfinished rollout work.

## Training source selection

| Deployment | Default ref | Init-script variable |
| --- | --- | --- |
| Mastering | `feature/metadata` | Hard-coded in the current init script |
| STAC | `feature/typed-cwl-inputs` | `STAC_TRAINING_REF` |
| How-to | `2.0.0` | `HOWTO_TRAINING_REF` |
| CWL EOAP | `feature/pde-typed-cwl` | `CWL_EOAP_TRAINING_REF` |
| Inference | `feature/pde-typed-cwl` | `INFERENCE_EOAP_TRAINING_REF` |
| Patterns | `2.0.0` | `APPLICATION_PACKAGE_PATTERNS_TRAINING_REF` |
| Dask | `feature/pde-typed-cwl` | `DASK_TRAINING_REF` |
| Contract-first | `main` | `EOAP_CONTRACT_FIRST_TRAINING_REF` |

These are shell variables read in the init container; they are not automatically forwarded from a host export. Refer to [source selection](../how-to/work-with-training-source.md) before changing them. Quickwin reads `QUICKWIN_TRAINING_REF` (default `feature/typed-cwl-release`), preserves dirty workspaces, and installs the module's hash-locked environment without rewriting notebooks.

## Runtime paths

| Path/resource | Meaning |
| --- | --- |
| `/workspace/<training-repo>` | PVC-backed course checkout used for execution |
| `/workspace/.venv` | Most module Python environments |
| `/workspace/eoap-contract-first/.venv` | Contract-first project environment |
| `/workspace/.local/share/hatch`, `.cache/hatch` | Workspace-backed mastering Hatch data/cache |
| `/workspace/.local/share/jupyter/kernels` | User kernel registrations under workspace HOME |
| `/opt/conda/bin/python` | PDE Python used for setup/runner wrappers |
| `/opt/calrissian-venv/bin/calrissian` | PDE's isolated Calrissian executable |
| `/workspace/lab-results` | Executed notebook copies and common docs artifacts |
| `/calrissian` | Calrissian shared PVC mount when enabled |
| `code-server-pvc` | Editor workspace, ReadWriteOnce |
| `calrissian-claim` | Calrissian shared storage, ReadWriteMany when enabled |
| `code-server-deployment` / `code-server-service` | Editor deployment/service in the module namespace |
| `init-file-on-volume` / `code-server` | Init/editor container names |

The chart uses a privileged editor by default for its training container workflow and launches code-server directly with `--auth none`. PDE entrypoint OAuth/Nextcloud behavior does not run through this chart command. The tested image identity is UID/GID 1001:100; validate the actual selected image when adapting it.

## Kernels and notebook roots

| Module | Python kernel | Notebook root relative to source |
| --- | --- | --- |
| Mastering | `mastering_env`, plus package-specific Hatch Bash kernels | `practice-labs` |
| Quickwin | `quickwin_env` | `practice-labs` |
| STAC | `stac_env` | `notebooks` |
| CWL | `cwl_env` | `notebooks` |
| Inference | `inference_env` | `practice-labs` |
| Patterns | `patterns_env` for interactive work | Markdown lessons; acceptance executes sixteen wrapped CWL cases |
| Dask | `dask_env` | Repository root; select application notebooks |
| Contract-first | `contract_env` for interactive work | Acceptance is source tasks |
| How-to | `cwl_how_to_env` for interactive work | Acceptance is workflows |

## S3 defaults

Migrated modules pin SeaweedFS Helm chart **4.48.0**; recorded image version is **4.48**. All-in-one storage is enabled, authenticated and backed by `emptyDir`; separate master/volume/filer deployments are disabled in the supplied values.

- Endpoint: `http://<module-release>-s3-seaweedfs-all-in-one:8333` from the matching namespace.
- Main training access key/secret: `test` / `test`; training defaults, not production credentials.
- AWS region: `us-east-1`; S3 addressing: `path`.
- Initialization: bounded readiness, then creation of `results` if absent.

Use the exact endpoint from the module's init script. The namespace/profile naming exceptions in the catalogue matter. Cross-namespace use requires the correct service DNS name; these modules are designed with separate storage, not a shared bucket service.

## Dask workers

The gateway chart and matching client protocol are pinned to **2025.4.0**. The PDE notebook worker tag is `eoap-dask-worker:2025.4.0-py312`; its Dockerfile is [Dockerfile.pde-worker](../../dask-gateway/Dockerfile.pde-worker). It installs both course packages on Python 3.12.11 using the training `requirements-runtime.txt` lock.

Build from `dask-gateway` with `task worker:build TRAINING_SOURCE=/path/to/dask-app-package`, then load with `task worker:load MINIKUBE_PROFILE=<profile>`. `WORKER_IMAGE` changes the build/load tag; update the backend and coder `daskGateway.image` configuration consistently if selecting another tag. Other clusters need the image available in their node runtime or registry.

Notebook defaults use two workers; cloudless task acceptance bounds the search with `MAX_ITEMS=2`. Larger budgets require checking gateway options, worker limits and cluster capacity. The bounded Calrissian test instead selects its application's published image; passing it does not prove every PDE notebook worker or scientific dataset path.
