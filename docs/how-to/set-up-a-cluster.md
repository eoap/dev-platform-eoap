# Set up a cluster

Use this guide to prepare a local Minikube cluster or point a migrated module at an existing Kubernetes cluster. Run commands on the host unless specified otherwise.

## Check tools and resources

Install Git, Docker, [Task](https://taskfile.dev/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm](https://helm.sh/docs/intro/install/), [Skaffold](https://skaffold.dev/docs/install/) and [Minikube](https://minikube.sigs.k8s.io/docs/start/) using their official instructions. This repository's Skaffold files use the `skaffold/v4beta9` configuration API; use a binary that accepts it.

```bash
git --version
docker version
task --version
kubectl version --client
helm version
skaffold version
minikube version
```

Most migrated module start tasks request 4 CPUs and 8192 MiB. How-to requests 16384 MiB; Dask requests 8 CPUs and 16384 MiB. These are start-task defaults, not measured minimums or guarantees for every workload. Account for the host OS, Docker, editor and workflow pods, plus downloaded imagery, image layers and retained virtual environments. Run one course at a time when resources are constrained.

Check [training refs](../reference/configuration.md#training-source-selection) before deployment. Fresh startup needs the configured branch available remotely or its checkout seeded locally.

## Create a module-specific Minikube profile

Example for STAC:

```bash
cd /path/to/dev-platform-eoap/stac-eoap
docker pull eoepca/pde-code-server:amd64
task start
task deploy
task test
```

`start` checks that the PDE image exists in the host Docker store, starts the profile and loads that image into Minikube. `deploy` registers the SeaweedFS Helm repository and uses Skaffold. Initial dependency installation and container pulls need working outbound networking.

To choose a different local profile and resources:

```bash
task start MINIKUBE_PROFILE=eoap-learning CPUS=4 MEMORY=12288
task deploy KUBE_CONTEXT=eoap-learning
task test KUBE_CONTEXT=eoap-learning
```

Pass the same context to later tasks. To stop this custom profile, use `task stop MINIKUBE_PROFILE=eoap-learning`; `stop` uses the profile variable, not `KUBE_CONTEXT`.

## Reuse an existing Minikube cluster

```bash
minikube profile list
kubectl config get-contexts
minikube -p <profile> image load eoepca/pde-code-server:amd64
cd /path/to/dev-platform-eoap/stac-eoap
task deploy KUBE_CONTEXT=<context>
task test KUBE_CONTEXT=<context>
```

Do not run `start` solely to select an already running context. A profile identifies a local Minikube cluster; a context identifies the Kubernetes API connection. Their names often match but serve different purposes.

## Use another Kubernetes cluster

Use a migrated module with `KUBE_CONTEXT` support and inspect its `skaffold.yaml`, `coder-values.yaml` if present, and the shared chart. Configure:

- Storage classes for the editor's ReadWriteOnce PVC and Calrissian's ReadWriteMany claim. Confirm actual mount behavior across nodes; a default class name alone does not prove RWX support.
- An image available to the nodes and compatible with their CPU architecture. Loading a host Docker image into Minikube does not publish it to another cluster.
- Available CPU/memory, namespace permissions, service accounts/RBAC and permitted Podman/editor security settings.
- Reachability of registries, Git repositories, extension downloads, STAC APIs and asset servers.
- Runner images, user/group IDs, node selection and writable shared paths required by the actual module workflows.

Then run the same acceptance sequence with the explicit context. This is a deployment path, not a claim that this repository has tested your cluster.

## Open the editor

```bash
kubectl --context <context> -n <namespace>   port-forward service/code-server-service 8000:8080
```

Open <http://127.0.0.1:8000>. Keep the terminal running. `task dev KUBE_CONTEXT=<context>` is an alternative that watches configuration and manages the declared port-forward; its cleanup behavior differs from a standalone port-forward. The chart launches code-server with authentication disabled. Keep access local, or configure authentication and network access before exposing it beyond your workstation.
