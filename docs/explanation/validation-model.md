# What acceptance proves

The platform tests two connected experiences: a learner completing the course, and a developer releasing a module that others can complete. Those experiences need more than a ready editor pod.

## Infrastructure, contracts and science

Smoke checks establish that the editor answers HTTP and the supplied object store can round-trip an object. Contract checks establish that CWL types and metadata resolve and that documentation can describe the interface. Notebook/workflow checks exercise the actual sequence and application paths. Output assertions establish whether the resulting catalog or raster is scientifically meaningful for the intended example.

These checks are complementary. A schema-valid document can bind an enum incorrectly at runtime. A successful Python function can fail in a container due to a missing shared library. A Kubernetes Job can exit successfully while producing a file the editor cannot read. The recorded UID/readability fix in mastering demonstrates why output usability is an acceptance condition.

## Why execute the entire learning sequence

Notebooks often build an image, create a fixture or write inputs needed later. Executing only the last notebook can unknowingly depend on state left by a previous session. Sorted runner output, module-specific dependency ordering and a fresh-environment test help distinguish a complete learning path from accidental success.

The runner fails on cell errors, but examples must also assert subprocess results and output expectations. The Dask applications previously swallowed processing exceptions; propagating failures makes automated acceptance reflect the real outcome.

## Fixtures and external dependencies

Inference acceptance uses a deterministic local STAC fixture and runs the actual ONNX model. It isolates model and packaging behavior from authenticated downloading. This is a useful, explicitly bounded claim: it does not establish that Copernicus credentials or network staging work.

Patterns uses real remote Landsat staging, and cloudless Dask acceptance uses two real satellite items. These paths exercise network and data integration but can fail when upstream services fail. Bounded retries recover transient transfers; exhausted retries still fail. EOPF's earlier HTTP 500 outage recovered; the real bounded notebook and typed CWL path now pass. Its full-tile capacity remains unverified. Record endpoint outages separately from independent gateway computation and teardown.

The distinction belongs in the evidence. A fixture is neither automatically inadequate nor automatically equivalent to live downloading: its value depends on the boundary being validated.

## Target-specific claims

A source contract can be portable while its tested execution is target-specific. Kubernetes storage access modes, Podman permissions, CPU architecture, registry manifests and distributed Python versions determine whether the course actually runs on a particular cluster.

Record architecture, cluster/context, image identity, resource budgets and dataset with the result. Repeat the relevant suite when those change. AMD64 local results do not imply ARM64 acceptance, and a Minikube image load does not imply registry publication.

## Documentation is part of the module

A self-learning module needs accurate descriptions and visible progression, as well as runnable code. Generating Markdown from typed metadata helps expose drift between the CWL interface and the learner-facing explanation. Reviewing that output remains necessary; a generator can faithfully render a misleading description.

This documentation separates guided tutorials from operational guides and technical reference so learners can practise without reading the entire deployment internals, while developers can find the exact configuration and acceptance limits when needed.
