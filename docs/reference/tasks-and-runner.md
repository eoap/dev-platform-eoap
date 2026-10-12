# Tasks and notebook runner

Use Task from a module directory, or its explicit `--dir` option. `task --list-all` shows the checked-in interface without executing a workload. Task variables are supplied as `NAME=value` arguments.

## Common migrated tasks

| Task | Effect | Important detail |
| --- | --- | --- |
| `start` | Starts a Minikube profile and loads PDE from host Docker | Requires the local image; controlled by `MINIKUBE_PROFILE` |
| `repos` | Registers/updates the SeaweedFS Helm repository | Needs outbound network |
| `deploy` | Runs Skaffold deployment with readiness checks | Uses `KUBE_CONTEXT`; does not run the full labs |
| `test` | Checks readiness, editor HTTP and S3 object roundtrip | Infrastructure smoke only |
| `dev` | Runs Skaffold watching and declared forwarding | Can redeploy/clean resources; keep its terminal open |
| `stop` | Stops the selected local Minikube profile | Uses `MINIKUBE_PROFILE`, not a generic Kubernetes context |
| `up` / default | Runs start, deploy and smoke in sequence | Creates/uses the local profile; unsuitable when only selecting a remote context |
| `cwl:docs` | Validates/generates contract documentation | Implemented by STAC, how-to, CWL, inference, patterns, Dask and contract-first |
| `labs` | Executes the module's learning acceptance | Meaning depends on the module |
| `labs:list` | Lists notebook selection without execution | Available in notebook modules; not how-to, patterns or contract-first |
| `test:lifecycle` | Backs up/recreates environment and resets S3 | How-to, CWL, inference, patterns, Dask and contract-first; run after workloads |

Quickwin now separates `KUBE_CONTEXT` from `MINIKUBE_PROFILE`; `dev` uses the selected cluster without starting Minikube, and `test:lifecycle` verifies retained workspaces, environment recreation and disposable S3. STAC and mastering do not currently expose `test:lifecycle`. The root Taskfile mostly launches older Skaffold workflows; module Taskfiles are the detailed interface.

## Shared variables

| Variable | Usual default | Scope |
| --- | --- | --- |
| `MINIKUBE_PROFILE` | Module-specific name | Local start/stop/image-load helpers |
| `KUBE_CONTEXT` | `MINIKUBE_PROFILE` | API target for migrated deployments/tests |
| `DRIVER` | `docker` | Local Minikube driver |
| `CONTAINER_RUNTIME` | `docker` | Local Minikube container runtime |
| `CPUS` / `MEMORY` | 4 / 8192; exceptions below | Local start request; memory in MiB |
| `IMAGE` | `eoepca/pde-code-server:amd64` | Primarily local image checks/load; does not rewrite the Skaffold image override |
| `NAMESPACE` | Module namespace | Task kubectl calls; does not rewrite namespace literals in Skaffold |
| `LAB` | Usually `*` | Notebook-relative directory, filename or glob |
| `CELL_TIMEOUT` | `1800` | Timeout per notebook cell in seconds |
| `LABS_LIST` | `false` | Runner list mode |

Changing `IMAGE` or `NAMESPACE` alone is insufficient to migrate a deployment: update corresponding chart/Skaffold configuration too. How-to requests 16384 MiB; Dask requests 8 CPUs and 16384 MiB. Patterns runs sixteen wrapped CWL cases without notebook-selection variables; Dask defaults to `eopf-sentinel-2/notebook.ipynb`.

## Specialized tasks

| Module | Interface | Meaning |
| --- | --- | --- |
| Mastering | `labs:kubernetes APPLICATION_PACKAGE_VERSION=<release>` | Chapter 5 with selected published package/images |
| Mastering | `labs:kubernetes-images` | Optional local developer image loading; separate from published artifact acceptance |
| How-to | `workflows` | Real Calrissian cases from the training source |
| Patterns | `wrap`, `labs` | Standalone eoap-cwlwrap composition and sixteen real-data Calrissian cases |
| Inference | `fixture`, `test:code`, `labs:run` | Local STAC fixture, focused source regression, selected lab execution |
| Dask | `worker:build`, `worker:load`, `test:dask` | Matching worker image, local loading, real two-worker computation and disposal |
| Contract-first | `training:task TRAINING_TASK=<source-task>` | Runs a source task in the locked course environment |

Mastering's current `APPLICATION_PACKAGE_VERSION` default is `2.0.0`; this describes configuration, not a claim that that version was the candidate tested. Recorded candidate evidence is for `2.0.0-rc.39.1` with the documented Job override.

## Runner CLI

The reusable runner is [run-practice-labs.py](../../mastering-app-package/scripts/run-practice-labs.py). Module tasks stream it into the editor rather than requiring the runner to exist in the course checkout.

| Option | Default | Behavior |
| --- | --- | --- |
| `--workspace` | `/workspace/mastering-app-package` | Training repository root |
| `--notebooks-dir` | `practice-labs` | Relative notebook root; absolute/parent traversal rejected |
| `--lab` | `*` | Relative selection; directories searched recursively |
| `--python-kernel` | `mastering_env` | Replaces Python notebook kernel selection |
| `--timeout` | `1800` | Positive seconds per cell |
| `--list` | `false` | `true` lists and exits without execution |
| `--output` | `/workspace/lab-results` | Root for timestamped executed copies |

Checkpoint notebooks are excluded. Selection is sorted and deduplicated. An empty selection is an error. Non-Python kernels are preserved. Execution uses each notebook's parent directory, disables prompt changes for Bash kernels, rejects notebook errors, stops at the first failed notebook, and saves that failed notebook in `finally`. Exit status 0 means all selected notebooks completed; the application's own assertions determine whether completion also proves correct output.
