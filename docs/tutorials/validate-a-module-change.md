# Validate a module change

This tutorial follows a small STAC module change through both repositories: the training source and its deployment. You will edit a CWL input description, generate documentation, run the notebooks and collect enough information for someone else to review the result.

Start with a working STAC deployment and the required training branch. Follow [cluster setup](../how-to/set-up-a-cluster.md) and [source synchronization](../how-to/work-with-training-source.md) if necessary. The example context and namespace are `eoap-stac`.

## 1. Inspect the two repositories

On the host:

```bash
cd /path/to/dev-platform-eoap
git status --short
cd /path/to/stac-eoap
git status --short
git branch --show-current
```

The deployment checkout supplies Helm values, initialization and test tasks. The training checkout supplies notebooks, application code, CWL and documentation-generation code. Create a feature branch in any repository you will change, preserving existing edits.

Choose one application CWL input whose existing description you can clarify. Change its `doc` to state the meaning of the value and its units or allowed values. Keep its ID and type unchanged for this exercise. Locate the corresponding notebook input and confirm the description matches actual usage.

## 2. Put the change in the tested workspace

In a running editor, first inspect the deployed checkout:

```bash
kubectl --context eoap-stac -n eoap-stac exec deployment/code-server-deployment   -c code-server -- git -C /workspace/stac-eoap status --short
```

If it has changes, preserve and reconcile them using the [source guide](../how-to/work-with-training-source.md). Copy your edited file to the same relative location in that checkout, using its actual path and current pod name. Do not assume a host file edit updates the PVC.

In the editor terminal, inspect the diff:

```bash
cd /workspace/stac-eoap
git diff
```

Confirm the deployed source contains the intended description. Record the host commit and any deployed diff: acceptance must refer to the source that was actually executed.

## 3. Run the acceptance sequence

From the host deployment directory:

```bash
cd /path/to/dev-platform-eoap/stac-eoap
task test KUBE_CONTEXT=eoap-stac
task cwl:docs KUBE_CONTEXT=eoap-stac
task labs:list KUBE_CONTEXT=eoap-stac
task labs KUBE_CONTEXT=eoap-stac
```

Expect six source CWL documents to validate and the five notebooks to complete. Real staging depends on external catalogue and imagery services. Read any failed notebook rather than treating a network failure as a successful package test.

Open the generated Markdown under `/workspace/lab-results/cwl-docs` and confirm that your input description appears. Open the executed notebooks from the run directory and check the final outputs, including the wrapped workflow's S3 result.

STAC currently has no `test:lifecycle` task. If this change also affects initialization, environments or storage, use the explicit STAC lifecycle command in the [lifecycle guide](../how-to/manage-lifecycle.md), after the notebooks finish.

## 4. Record and commit

Collect the source commit, deployed diff, context, architecture, image identity, commands, notebook run ID, documentation output and limitations in an acceptance note. Use the [acceptance template](../how-to/validate-a-module.md#record-the-result).

Review and commit the intended training change using a Conventional Commit, for example:

```bash
git add <changed-cwl-file>
git commit -m "docs(cwl): clarify STAC input semantics"
```

Commit deployment changes separately if you made any. Publishing the branch or a release is a separate step; local acceptance does not publish training content or container images.

You have now tested both the documentation contract and the real learning sequence against a named deployed snapshot.
