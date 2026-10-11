# C4 architecture model

The [C4 model](https://c4model.com/diagrams) describes software at four levels of zoom: system context, containers, components and code. These views explain the implemented EOAP learning platform from a learner's surroundings down to one acceptance tool's code. They complement the [execution architecture](../architecture.md) and lifecycle/validation diagrams.

The views describe the current migrated deployment pattern. They do not imply that every historical module has migrated, that ARM64 is accepted, or that deployment on every Kubernetes cluster is tested. Read the [validation status](../../reference/validation-status.md) alongside the model.

## Choose a level

| Level | Main question | Scope | Audience |
| --- | --- | --- | --- |
| [1: System context](system-context.md) | Who uses the platform, and what does it depend on? | The platform as one system and its environment | Learners, course authors and platform reviewers |
| [2: Containers](containers.md) | Which applications and data stores deliver it? | Platform runtime applications and storage responsibilities | Module developers and operators |
| [3: Components](components.md) | How does one application divide its responsibilities? | The learning workspace runtime | Developers diagnosing or extending execution |
| [4: Code](code.md) | Which code interfaces implement one component? | The notebook acceptance runner | Maintainers changing the runner |

Each level has an explicit boundary. The lower-level diagrams expand selected elements rather than repeating the complete platform at increasing visual density. Level 3 expands the **Learning workspace** container in Level 2. Level 4 expands the **Notebook acceptance runner** component in Level 3. It is not a class diagram of every training repository.

## How to read the notation

The diagrams use PlantUML with C4-style element names, types, responsibilities and labeled relationships. A custom drawing library is not required to apply C4. Sources are local and the SVGs are rendered before the site build.

- **Person:** a user role, such as self-learner or module developer.
- **Software system:** a capability with a meaningful boundary, such as this learning platform or an external artifact service.
- **Container:** an application/runtime or data store within a system. In C4 this is an architectural term; it does **not** mean one Docker container or Kubernetes pod.
- **Component:** a cohesive runtime responsibility inside one container. A component may use multiple functions or upstream libraries.
- **Code:** concrete modules, functions, classes and dependencies implementing the selected component.

Element labels include technologies when the view needs them. Gray elements are outside the selected boundary; teal elements are in scope, and amber data stores identify file/object storage. Arrows state the relationship or mechanism, not merely “uses”. Some secondary relationships are omitted for readability and documented in the text.

## Static structure and runtime behavior

C4 levels describe static structure. The [source synchronization](../../how-to/work-with-training-source.md), [module acceptance](../../how-to/validate-a-module.md) and [storage lifecycle](../storage-and-environments.md) diagrams describe behavior over time. Neither a static C4 view nor a successful render proves deployment acceptance.

Minikube belongs to the deployment setting. A multi-node cluster, alternative storage class or registry changes deployment assumptions without changing the learner/developer roles in the context view. Consult [cluster setup](../../how-to/set-up-a-cluster.md) when applying those changes.

## Maintain the model

Update the relevant view when a boundary, application, data store, execution responsibility or concrete code dependency changes. Keep source and SVG changes together and verify labels against repository files. Regenerate with `task docs:diagrams`; see [diagram tooling](../../diagrams/README.md).

The official C4 guidance allows using only the levels that add value. This platform uses a focused Level 4 example because runner failure handling and evidence retention directly affect module acceptance; it does not require code diagrams for every exercise. See the [official diagram overview](https://c4model.com/diagrams) for the model's scope.
