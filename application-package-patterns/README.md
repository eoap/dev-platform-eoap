# application-package-patterns development module

Deploy the `application-package-patterns` training checkout in the EOEPCA PDE editor. The deployment
uses `eoepca/pde-code-server:amd64` and a dedicated authenticated SeaweedFS 4.48.0
release with disposable S3 data. Workspace and Calrissian PVCs are retained.

Run `task start` for the optional local Minikube setup, or select an existing
Kubernetes cluster with `task deploy KUBE_CONTEXT=<context>`. Then run `task test`,
`task cwl:docs`, and `task labs` using the same context. `task dev` forwards the
editor to localhost:8000. Configure the storage classes in `skaffold.yaml` for
your cluster; the supplied `standard` class is the tested local configuration.

Training source: https://github.com/eoap/application-package-patterns. Feature-branch changes must be
published or copied into the persistent workspace before deploying them. Init
preserves existing edited checkouts. No registry or Git publication is performed
by the validation tasks.

S3 endpoint: `http://eoap-application-package-patterns-s3-seaweedfs-all-in-one:8333`, region `us-east-1`,
path addressing, credentials `test`/`test`, initialized bucket `results`.
Only the AMD64 local Kubernetes configuration has been selected for acceptance;
other architectures and storage providers need their own validation.

The training feature branch now targets 2.0.0 with twelve typed CWL patterns and
four additional optional-port acceptance cases. Lessons are Markdown pages;
`task labs` executes their wrapped CWL with Calrissian using real EO data.
`task wrap` composes the standalone documents through eoap-cwlwrap.

The hash-locked Python environment and immutable image references come from the
training checkout. `mastering-staging.lock.json` records the independently
published GHCR stage-in/out CWL and containers from mastering 2.0.1-rc.44.1.
The stage-in adapter downloads the green, red and nir08 assets required by these
patterns with a 300-second transfer timeout. No sibling host clone is required.

All sixteen acceptance cases passed from clean commit `4a1de5c` on AMD64
Minikube, followed by editor/S3 smoke and retained-workspace/fresh-environment/
disposable-S3 lifecycle checks. Stage-out disables upload caching and gives
each result its own S3 prefix, preventing scattered-output collisions.
Evidence: `/workspace/lab-results/patterns-4a1de5c.zip` and
`/calrissian/patterns/20261011T160535Z`. Lifecycle validation cleared the
uploaded S3 objects after their contents were checked and the evidence saved.

[PR acceptance CI](https://github.com/eoap/application-package-patterns/actions/runs/38153992055)
passed all sixteen cases, 27 runner tests and strict documentation. Stable
promotion requires promotion of the upstream mastering staging candidate and
updating the lock to its stable publication.
The release preparation is tracked in training PR #15 and mastering PR #18.
