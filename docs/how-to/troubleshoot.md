# Troubleshoot startup and lab failures

Start with the stage that failed. Use the real context and namespace; each course has its own namespace. Avoid deleting workspaces as a general repair.

## Initialization or deployment is stuck

```bash
kubectl --context <context> -n <namespace> get pods,pvc
kubectl --context <context> -n <namespace> describe pod <pod-name>
kubectl --context <context> -n <namespace> logs <pod-name> -c init-file-on-volume
kubectl --context <context> -n <namespace> logs <pod-name> -c init-file-on-volume --previous
```

`Pending` commonly requires checking resource requests, PVC binding and storage-class support. `ImagePullBackOff` requires inspecting the exact image, registry access and architecture. Init failures may be an unpublished branch, an inaccessible registry/GitHub API, failed extension download, incompatible dependencies or unavailable S3.

For a clone failure, inspect the required ref and use the [source guide](work-with-training-source.md). For an existing dirty checkout, confirm it includes the helper scripts and dependency declarations required by the new deployment.

## Editor is healthy but notebooks cannot run

In the editor terminal:

```bash
jupyter kernelspec list
/workspace/.venv/bin/python --version
uv pip check --python /workspace/.venv/bin/python
```

Inspect the selected kernel's `argv` and check its interpreter exists. Contract-first uses `/workspace/eoap-contract-first/.venv`; mastering also has Hatch kernels. A healthy code-server process does not prove that each interpreter or notebook package exists.

If initialization registered a kernel in an init-private path, fix the init/editor environment paths and recreate/register the kernel while preserving user files.

## S3 readiness or authentication fails

In the editor terminal, inspect configured non-secret settings:

```bash
aws configure get endpoint_url
aws configure get region
aws configure get s3.addressing_style
aws s3api list-buckets
```

The migrated defaults use the module-specific SeaweedFS service on port 8333, region `us-east-1`, path addressing and test/test training credentials. Check that the correct service and namespace exist. Do not copy a service name from another course or retain a LocalStack port 4566 endpoint in a migrated module.

Inspect the SeaweedFS pod/events if initialization exhausts its readiness attempts. Do not print real credential files into logs.

## A notebook completes without the expected output

Inspect the executed copy and the application logs. Check that subprocess/CWL return values are asserted and that caught exceptions propagate as failures. Confirm File/Directory globs match generated files and that the output is readable by the editor's user.

For typed inputs, compare the job record with the actual definition and CLI binding. URI records need a `value`; a BBox must preserve its expected coordinate order and CRS; enum values may require explicit conversion to the CLI's CRS spelling.

## Podman or a Kubernetes task fails

Inspect container errors, writable mounts, current UID/GID and network access. PDE's tested user is 1001:100; a notebook hard-coding UID 1000 can produce permission failures. Fix the training source rather than repeatedly patching it during init.

For Kubernetes execution, inspect task pod events/logs, RBAC, shared `/calrissian` access, image availability, memory limits and OOM events. Clear inappropriate inherited `CWLTOOL_OPTIONS` when the module's runner explicitly selects Calrissian or no-container execution. Do not globally change options without checking notebook paths that use Podman.

## External data fails

Distinguish HTTP status errors, authentication, missing items, expired signed URLs, incomplete transfers and timeouts. Rerun only after confirming the failure is transient or after fixing its cause. Bounded network retries must eventually fail rather than masking missing data.

The recorded EOPF item endpoint returned HTTP 500; full EOPF science execution remains blocked despite successful independent Dask checks. Inference's local staging fixture validates real ONNX inference without proving authenticated Copernicus downloading.

## Dask workers cannot deserialize tasks

Confirm Python, Dask/distributed versions and package dependencies match between notebook clients and workers. The published course worker images use Python 3.10 whereas PDE uses 3.12; the matching local worker and shared runtime lock address that observed mismatch.

Use the Dask module's `worker:build` and `worker:load` tasks for Minikube, then verify the backend image setting and cleanly rerun the workload. Inspect worker memory/CPU limits if deserialization succeeds but computation fails. See [Dask configuration](../reference/configuration.md#dask-workers).
