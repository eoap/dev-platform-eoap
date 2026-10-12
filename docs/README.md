# Learn and develop EO Application Packages

This repository provides Kubernetes development environments for Earth Observation Application Package (EOAP) e-learning. Each deployment opens a training repository in a browser editor, installs its learning environment, and supplies services needed by its exercises. Use Minikube for a local learning cluster, or adapt the deployment to another Kubernetes cluster.

The course content lives in separate repositories. This repository supplies the environment and acceptance tasks; it is also where module developers check that their content actually works in that environment.

## Choose your path

| Your goal | Start here | Continue with |
| --- | --- | --- |
| Learn through a first working example | [Your first EOAP learning session](tutorials/first-learning-session.md) | [Learning pathways](reference/learning-pathways.md) |
| Develop and test an e-learning module | [Validate a module change](tutorials/validate-a-module-change.md) | [Acceptance workflow](how-to/validate-a-module.md) |
| Run a specific exercise again | [Run and collect lab results](how-to/run-labs.md) | [Troubleshooting](how-to/troubleshoot.md) |
| Prepare unpublished course changes | [Select and synchronize training source](how-to/work-with-training-source.md) | [CWL requirements](reference/cwl-contract.md) |
| Understand the platform | [Architecture](explanation/architecture.md) | [Storage and environments](explanation/storage-and-environments.md) |

## Documentation map

These documents follow [Diátaxis](https://diataxis.fr/): tutorials teach through guided practice, how-to guides solve tasks, reference describes interfaces, and explanation develops understanding.

### Tutorials: learn by doing

- [Your first EOAP learning session](tutorials/first-learning-session.md): deploy CWL EOAP, open the editor, complete and inspect exercises.
- [Validate a module change](tutorials/validate-a-module-change.md): change STAC training content, run acceptance, and retain evidence.

### How-to guides: accomplish a task

- [Set up Minikube or use an existing cluster](how-to/set-up-a-cluster.md)
- [Select and synchronize training source](how-to/work-with-training-source.md)
- [Run notebooks, workflows, and collect evidence](how-to/run-labs.md)
- [Validate a module before release](how-to/validate-a-module.md)
- [Develop typed standalone CWL](how-to/develop-typed-cwl.md)
- [Add a deployment for a new module](how-to/add-a-module.md)
- [Recreate environments and manage storage](how-to/manage-lifecycle.md)
- [Diagnose startup and execution failures](how-to/troubleshoot.md)

### Reference: look up the details

- [Module catalogue and learning pathways](reference/learning-pathways.md)
- [Task and runner interfaces](reference/tasks-and-runner.md)
- [Configuration and filesystem](reference/configuration.md)
- [CWL and module contract](reference/cwl-contract.md)
- [Recorded validation and current limits](reference/validation-status.md)
- [PlantUML sources and SVG regeneration](diagrams/README.md)

### Explanation: understand the design

- [Architecture and execution layers](explanation/architecture.md)
- [C4 model: context, containers, components and code](explanation/c4/README.md)
- [Persistent workspaces and disposable data](explanation/storage-and-environments.md)
- [What acceptance proves](explanation/validation-model.md)

## Before you begin

Read [cluster setup](how-to/set-up-a-cluster.md) and check [training source availability](how-to/work-with-training-source.md). Some configured feature branches contain local commits that may not yet exist remotely. A successful image pull cannot supply those commits.

The recorded acceptance is for an AMD64 Docker-backed Minikube cluster. Other Kubernetes clusters are supported as configuration targets by the migrated task interfaces, but need their own validation. ARM64 acceptance and a shared multi-platform PDE artifact remain outstanding. See the [status reference](reference/validation-status.md) and [implementation plan](../PLAN.md).

Commands identify whether they run on the host or in the browser editor. Examples using `KUBE_CONTEXT` apply to the migrated modules listed in the task reference. Quickwin currently has a different interface.

## Preview and build this documentation

From the repository root, with uv and Task installed:

```bash
task docs:serve
task docs:build -- --strict
```

The preview normally opens at <http://127.0.0.1:8000>; stop another module's
port-forward first if it uses the same port. Build output goes to `site/`, which
is ignored by Git. Dependencies are pinned in `scripts/requirements-docs.txt`.
The Material theme, palettes, Markdown extensions, Mermaid and image zoom
follow the mastering module's documentation configuration.

Repository-relative links to files outside `docs/` are converted to GitHub
source links during rendering; the Markdown files retain their local links.
Set `extra.source_ref` and `edit_uri` in `mkdocs.yaml` to the published branch
or tag that accompanies the site. The default is `main`; unpublished local
changes need publication before their source links will be available there.
