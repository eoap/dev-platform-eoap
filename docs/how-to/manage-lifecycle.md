# Manage workspaces, environments and disposable S3

Use this guide to pause a course, free resources or verify initialization after a dependency/image change. Export wanted S3 outputs and finish all running workloads before restarting anything.

## Pause an editor without deleting its workspace

```bash
kubectl --context <context> -n <namespace> scale   deployment/code-server-deployment --replicas=0
```

This frees editor resources but leaves the module's storage/services and PVCs. To resume, scale to one and wait for rollout. Initialization runs for the new pod.

To stop an entire local profile, use `task stop MINIKUBE_PROFILE=<profile>` from a migrated module directory. Do not substitute `minikube delete` when you intend to keep the session: profile deletion can remove cluster-backed storage despite Helm keep annotations.

## Run lifecycle acceptance

Modules with `test:lifecycle` currently include how-to, CWL EOAP, inference, Dask, patterns and contract-first:

```bash
task test:lifecycle KUBE_CONTEXT=<context>
```

The shared script writes a workspace sentinel and an S3 object, moves the current environment to a timestamped backup, restarts S3 and the editor, and checks the new environment, retained files, initialized bucket and disappearance of the old S3 object. This is a mutating test, not a read-only health check.

STAC lacks the task wrapper but can use the same script from the repository root:

```bash
bash scripts/test-module-lifecycle.sh   <context> eoap-stac eoap-stac-s3-seaweedfs-all-in-one /workspace/.venv
```

Mastering has additional Hatch environments and registered Bash kernels; follow its module README and verify those interpreters as well. Do not infer complete mastering kernel acceptance from moving only `/workspace/.venv`.

## Recover from failed environment recreation

Inspect the init logs. Confirm the old environment exists at the backup path printed or derived from the script's timestamp. Fix dependency or source availability first, then rerun initialization. Keep user notebooks and `.git` data intact.

A backup virtual environment is useful for inspection, but is not guaranteed executable after changing Python path or architecture. Recreate with compatible dependencies rather than expecting a copied interpreter to work indefinitely. After acceptance and exporting evidence, deliberately remove obsolete backups if disk space is needed.

## Understand removal behavior

Workspace `code-server-pvc` and enabled `calrissian-claim` have Helm keep annotations. This helps preserve them across Helm/Skaffold removal, but is not a backup or protection against deleting a namespace, PVC, cluster or storage backend.

SeaweedFS uses `emptyDir`: data belongs to its pod lifecycle. Pod replacement discards it; restarting a container within the same pod may leave it present. Initialization recreates `results`. Export catalogs and assets before pod recreation, `skaffold dev` cleanup, uninstall or redeploy if you need them.

`task dev` watches deployments and may clean managed resources when it exits. A standalone `kubectl port-forward` only forwards traffic and stops doing so on Ctrl-C. Choose the command whose lifecycle matches your task.
