# Quickwin development module

Quickwin uses the local AMD64 pilot image `eoepca/pde-code-server:amd64` and a
separate SeaweedFS Helm release (chart 4.48.0, image 4.48). The shared coder image
default remains unchanged. ARM64 and a published PDE manifest digest are pending.

From this directory, use:

```bash
task up
task test
task labs:list
task labs
task dev
task stop
```

These tasks require Task, Docker, Minikube, Helm, kubectl, Skaffold, and the local
PDE image. The default Docker-backed profile is `eoap-quickwin`, with 4 CPUs and
8192 MiB. Override `MINIKUBE_PROFILE` to target an existing cluster. Run one
module editor at a time on a node sized for one module. `task up` runs deployment
smoke checks; notebook execution is a separate command.

Initialization preserves an existing training checkout and installs module
packages using uv with PDE's Python. Initialization replaces the container
notebook's legacy `--user=1000:100` argument with the current UID/GID so the
container can write into the mounted workspace. Other notebook content is
preserved. The tested module environment pins Click
8.1.8. Python notebooks use
`quickwin_env`; Bash notebooks use PDE's Bash kernel and Podman configuration.
Notebook results are saved under unique `/workspace/lab-results/` directories.
Select a notebook with `task labs LAB='1 - Application.ipynb'`. Later notebooks
require the application/container outputs from preceding notebooks.

AWS CLI uses credentials `test` / `test`, region `us-east-1`, path addressing,
and endpoint `http://eoap-quickwin-s3-seaweedfs-all-in-one:8333`. Initialization
waits for S3 and creates `results`. Smoke checks upload, download, compare, and
remove a temporary object.

SeaweedFS objects use disposable `emptyDir` storage; pod recreation or release
removal loses them. A container restart in the same pod can retain data.
Recreating just the storage pod also removes its buckets; recreate `results`
with AWS CLI or restart the editor to rerun initialization. The chart's
credential Secret can remain after uninstall and contains no S3 objects.

The coder chart retains the workspace PVC on Helm uninstall. Reinstalling the
same release in the same namespace reuses its files; remove the PVC explicitly
only when its contents can be discarded. Published-image selection, ARM64,
and the remaining modules are covered in [the migration plan](../PLAN.md).

Validation on 10 October 2026 passed on Docker-backed Minikube profile
`eoap-mastering-app-package-docker`, namespace `eoap-quickwin`: fresh deployment,
editor HTTP 200, S3 upload/download/delete, and all four notebooks (application,
container build/run, CWL CommandLineTool, and CWL workflow). The training source
was `f81b825` with the container UID fix. That fix was also saved uncommitted in
`/data/work/github-com/eoap/quickwin`; initialization applies the same adjustment
to fresh checkouts. No training source was pushed.

Executed notebooks are under `/workspace/lab-results/20261010T202811545301Z/`
(application passed; initial container failure retained) and
`/workspace/lab-results/20261010T203209631926Z/` (successful container/CWL rerun).
Host copies are `/tmp/quickwin-migration-initial` and
`/tmp/quickwin-migration-container-cwl`. Mastering's editor was scaled to zero
during Quickwin validation to fit the node; its workspace volumes were retained.
