# Run labs and collect results

Use a module's own Taskfile from its directory. The root Taskfile contains older Skaffold launchers and does not provide the full acceptance interface for every module.

## Discover and select notebooks

For STAC:

```bash
cd /path/to/dev-platform-eoap/stac-eoap
task --list-all
task labs:list KUBE_CONTEXT=<context>
```

Copy a notebook name from the listing to run it:

```bash
task labs KUBE_CONTEXT=<context> LAB='<notebook>.ipynb' CELL_TIMEOUT=1800
```

Use `LAB='*'` for the full selection, or a relative directory or glob. Quote globs so the host shell does not expand them. Select dependent notebooks together when one creates a fixture or image used by another. A passing final notebook without its prerequisites is not full-course acceptance.

The runner executes in each source notebook's directory. It sorts the selected paths, preserves non-Python notebook kernels, selects the module's Python kernel, stops at the first error and saves an executed copy even on failure. `CELL_TIMEOUT` is seconds **per cell**, not a limit for the entire suite.

## Use module-specific execution paths

- **How-to:** use `task workflows KUBE_CONTEXT=<context>`; this course's acceptance runs ten Calrissian workflow cases instead of a notebook suite.
- **Inference:** `task labs` runs code tests and all six labs in dependency order with a deterministic local staging fixture and the real ONNX model. Use `task labs:run LAB='<selection>' KUBE_CONTEXT=<context>` for a subset. Selecting a fixture does not test authenticated Copernicus downloading.
- **Contract-first:** `task labs KUBE_CONTEXT=<context>` runs the source `reference:test` gate. `task cwl:docs` runs `artifacts:derive`; there is no notebook listing task.
- **Patterns:** the default is `LAB='pattern-*.ipynb'`; use the full twelve-notebook sequence for acceptance.
- **Dask:** build/load matching workers first. Then use `task labs LAB='cloudless-mosaic/notebook.ipynb' MAX_ITEMS=2 KUBE_CONTEXT=<context>`. The default selects EOPF; its remote endpoint was failing during recorded acceptance. The bounded control-path test is `task test:dask`.
- **Mastering:** select published chapter 5 artifacts with `task labs:kubernetes APPLICATION_PACKAGE_VERSION=<release> KUBE_CONTEXT=<context>`. The full `task labs` also prepares the published-artifact path. The current Taskfile default is `2.0.0`; explicitly select the candidate you intend to validate and record it.
- **Quickwin:** its tasks currently select context using `MINIKUBE_PROFILE`, rather than `KUBE_CONTEXT`. Check the Taskfile before using a common command.

## Save command logs

On a Bash host, preserve the task's exit status when using `tee`:

```bash
set -o pipefail
task labs KUBE_CONTEXT=<context> 2>&1 | tee lab-run.log
```

A failed task remains failed. Do not use output filtering that hides errors or replace a nonzero result with a passing summary.

## Export artifacts

Notebook artifacts normally live under `/workspace/lab-results/<UTC-run-id>`. Generated contract Markdown normally lives under `/workspace/lab-results/cwl-docs`. How-to workflow artifacts are under `/calrissian/how-to/<UTC-run-id>`; Dask acceptance artifacts are under `/calrissian/dask-acceptance/<UTC-run-id>`. Contract-first derives artifacts in its source project's configured paths; inspect the task output.

```bash
kubectl --context <context> -n <namespace> get pods -l app=code-server
kubectl --context <context> -n <namespace> cp -c code-server   <pod-name>:/workspace/lab-results/<run-id> ./acceptance/<run-id>
```

Copy S3 outputs separately before restarting its pod. In the editor terminal, use the module's configured endpoint:

```bash
aws s3 ls s3://results/ --recursive
aws s3 cp s3://results/<run-prefix>/ /workspace/exported-results/ --recursive
```

Verify that the copied STAC catalog resolves its items and assets and that rasters have the expected dimensions, CRS and values. A bucket listing or a zero exit code alone does not prove scientific correctness.
