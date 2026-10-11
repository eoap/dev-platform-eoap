# Your first EOAP learning session

By the end of this tutorial you will have opened a course in the browser, followed an application from a command line into a container and a CWL package, and saved an executed notebook as evidence of your learning.

We use **CWL EOAP** because its three notebooks form a short progression. You need an AMD64 host with Docker running, Git, Task, kubectl, Helm, Skaffold and Minikube. Allow capacity for a 4-CPU, 8-GiB cluster plus host overhead. The editor image and container builds also need substantial disk space.

## 1. Prepare the checkout and image

On the host, enter your checkout:

```bash
cd /path/to/dev-platform-eoap/cwl-eoap
```

Confirm that the training branch `feature/pde-typed-cwl` is available from the CWL EOAP repository, or use the [local source guide](../how-to/work-with-training-source.md) before continuing. The initialization script requires its typed-CWL content.

The `start` task loads an image from the host Docker store. Acquire it before starting:

```bash
docker pull eoepca/pde-code-server:amd64
docker image inspect eoepca/pde-code-server:amd64
```

If the tag is unavailable to you, obtain the built PDE image from your image provider and load it locally. Do not substitute another tag without checking the environment and module compatibility.

## 2. Start and deploy

Run on the host:

```bash
task start
task deploy
task test
```

The default profile and namespace are `eoap-cwl`. Initialization clones the course, installs dependencies, registers notebook kernels and initializes the `results` bucket. The smoke task checks editor HTTP health and an S3 upload/download/delete round trip.

If deployment fails, inspect the init-container logs using the [troubleshooting guide](../how-to/troubleshoot.md). Fix the error before following the exercises.

## 3. Open the course

Keep this command running in a second host terminal:

```bash
kubectl --context eoap-cwl -n eoap-cwl port-forward service/code-server-service 8000:8080
```

Open <http://127.0.0.1:8000>. The editor opens `/workspace/cwl-eoap`. In the file explorer, open `notebooks` and begin with the command-line notebook. Select **Python (cwl-eoap)** for Python notebooks; use the notebook's Bash kernel where its instructions require it.

Work through the three notebooks in their listed order. Run cells individually and read the result before continuing. Notice the changes in what describes execution: Python and command-line arguments first, the container environment next, and typed CWL inputs/outputs last.

An application container build can take longer than a small Python cell. Completion means that the cell finished successfully and the expected output is available, rather than merely that a process started.

## 4. Confirm the complete exercise

On the host, list the selected notebooks, then execute them automatically:

```bash
task labs:list
task cwl:docs
task labs
```

The runner prints notebook names, `PASSED` messages and an output directory under `/workspace/lab-results/<UTC-run-id>`. It saves executed copies without overwriting the teaching notebooks. Inspect a copy in the editor and compare it with the notebook you ran manually.

The metadata check validates the distributed CWL and generates Markdown. It complements execution by checking the contract a learner reads.

## 5. Save what you learned

Write a short note in the workspace describing the application inputs, its output File, and what the container contributes. Download the note and the executed notebook you want to keep. To copy the results from the host, first identify the current pod:

```bash
kubectl --context eoap-cwl -n eoap-cwl get pods -l app=code-server
```

Then use the pod name and run ID printed by your own session:

```bash
kubectl --context eoap-cwl -n eoap-cwl cp -c code-server   <pod-name>:/workspace/lab-results/<run-id> ./learning-results
```

Angle-bracket values are placeholders; replace them before running the command.

## 6. Pause the session

Stop the port-forward with Ctrl-C. Then run:

```bash
task stop
```

This stops the `eoap-cwl` Minikube profile. It is different from deleting a cluster or removing its volumes. Your workspace uses a PVC; S3 objects are disposable and must be copied out if needed.

Next, choose [a learning pathway](../reference/learning-pathways.md). STAC adds catalogue-based staging; mastering adds a longer packaging and Kubernetes sequence.
