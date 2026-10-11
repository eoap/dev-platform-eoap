# Add a module deployment

Use this guide to connect an e-learning repository to the development platform. Create the training repository separately if it does not yet exist; adding a deployment directory does not generate a course.

## Inventory the course

Identify its repository and intended ref, notebook/doc locations, source quality commands, Python/tool dependencies, kernel types, CWL entrypoints, images, data sources, authentication, output buckets and special services. Read its contribution instructions before modifying source.

Check resource behavior on representative data. Distinguish local Podman notebooks, Calrissian task pods, Dask workers and source-only tests. Decide what evidence establishes success for that particular course.

## Add the deployment directory

A migrated module normally has:

```text
<module>/
  README.md
  Taskfile.yaml
  skaffold.yaml
  coder-values.yaml          # where needed for chart overrides
  seaweedfs-values.yaml
  files/
    init.sh
    bash-rc
    bash-login
```

Start from a comparable maintained module, such as CWL EOAP for a notebook course or contract-first for task-based reference validation. Review every copied namespace, service name, workspace path, kernel, source ref and S3 endpoint. Copying a template without checking these values can point a module at another course's storage.

Set an explicit PDE image override. Do not rely on the shared chart's legacy default. Give the course its own namespace and SeaweedFS Helm release. Pin chart/image versions and use the agreed disposable all-in-one configuration; initialize the actual required buckets after bounded readiness checks.

## Make initialization reproducible

The shared chart invokes the init script through `sh`, so retain the Bash re-exec guard when using Bash syntax. Make failures visible with strict error handling, preserve dirty checkouts and create the environment using the intended Python. Install declared dependencies, check compatibility and register the correct kernels.

Keep tools from PDE when compatible rather than introducing architecture-specific binary downloads. Use the intended isolated Calrissian executable and inspect its provenance. Ensure init and editor use workspace-backed paths for environment/kernel files; files in an init-container-private home disappear for the editor.

Keep training changes in the training repository instead of silently rewriting notebooks during init. Document the ref selection and what must be published before a fresh clone works.

## Add task interfaces

Implement `start` as an optional local Minikube helper and use `KUBE_CONTEXT` independently for `deploy`, `test`, execution and `dev`. Make task names describe what they do. Supply lab discovery/selection if notebooks are present, contract docs validation and the real module-specific workload gate.

Run lifecycle acceptance after workloads and preserve user PVCs. Review Helm keep annotations, environment backup paths and disposable S3 behavior. Add meaningful focused regressions for bugs exposed during execution, using the source project's tools.

## Review and integrate

Run [module acceptance](validate-a-module.md) and collect evidence. Add the module to the [catalogue](../reference/learning-pathways.md), configuration and status references, and the root README. Make feature-branch Conventional Commits in each changed repository.

Release readiness also requires accessible source branches and images. A locally seeded checkout or Minikube-loaded worker image must be documented as local-only until published. CI and ARM64 acceptance need explicit work; they do not follow automatically from adding the directory.
