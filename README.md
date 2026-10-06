# Development platform for Earth Observation Application Package training modules

## Requirements

Before you begin, make sure you have the following tools installed and set up on your local environment:

### Skaffold

Skaffold is used to build, push, and deploy your application to Kubernetes. 

You can install it by following the instructions [here](https://skaffold.dev/docs/install/#standalone-binary).

### Helm

Helm is a package manager for Kubernetes, enabling you to manage Kubernetes applications easily. 

You can install it by following the steps [here](https://helm.sh/docs/intro/install/).

### Minikube

Minikube runs a local Kubernetes cluster, ideal for development and testing. 

You can install it by following the guide [here](https://minikube.sigs.k8s.io/docs/start).

Start your minikube instance with:

```
minikube start
```

### Optional requirements

#### Kubectl

Kubectl is a command-line tool for interacting with Kubernetes clusters. It allows you to manage and inspect cluster resources. While not strictly required, it's highly recommended for debugging and interacting with your Kubernetes environment.

You can install it by following the instructions [here](https://kubernetes.io/docs/tasks/tools/#kubectl).

#### OpenLens

OpenLens is a graphical user interface for managing and monitoring Kubernetes clusters. It provides a visual way to interact with resources. 

While it's optional, it can significantly improve your workflow. You can download it [here](https://github.com/MuhammedKalkan/OpenLens?tab=readme-ov-file#installation).

### Add the helm repositories


```
helm repo add localstack https://helm.localstack.cloud
helm repo add zoo-project https://zoo-project.github.io/charts/
```

### Checking the requirements

After installing these tools, ensure they are available in your terminal by running the following commands:

```bash
skaffold version
helm version
minikube version
```

If all commands return a version, you’re good to go!

## Mastering Earth Observation Application Packaging with CWL 

### Prepare Minikube storage

This module requests the `hostpath` StorageClass for both `code-server-pvc` and
`calrissian-claim`. Minikube normally provides a class named `standard`, so create
the additional class before running Skaffold:

```sh
minikube addons enable storage-provisioner
kubectl apply -f - <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
YAML
kubectl get storageclass
```

These settings are for Minikube's built-in provisioner. It creates the PVs and
directories inside the Minikube node automatically; no Mac directory mount is
required. See [Minikube persistent volumes](https://minikube.sigs.k8s.io/docs/handbook/persistent_volumes/).

### Enable AMD64 emulation on Apple Silicon

The module uses `eoepca/pde-code-server:1.0.0`, an AMD64 image. On an ARM64
Minikube node, it fails with `exec /usr/bin/sh: exec format error` unless AMD64
emulation is available. Check the node architecture:

```sh
kubectl get nodes -o custom-columns=NAME:.metadata.name,ARCH:.status.nodeInfo.architecture
```

For an ARM64 node using the Docker runtime inside Minikube (tested with the
`qemu2` driver), run:

```sh
minikube ssh -- 'mountpoint -q /proc/sys/fs/binfmt_misc || sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc'
minikube ssh -- 'docker run --privileged --rm tonistiigi/binfmt --install amd64'
```

The first command mounts the kernel's executable-format registry in the VM.
Without this mount, the installer may report success but leave no emulator
registered after its container exits. The second command registers the AMD64
emulator using a privileged container inside Minikube. See the
[binfmt documentation](https://github.com/tonistiigi/binfmt).

Verify registration and test the actual workshop image:

```sh
minikube ssh -- 'cat /proc/sys/fs/binfmt_misc/qemu-x86_64'
minikube ssh -- 'docker run --rm --platform linux/amd64 --entrypoint /usr/bin/sh eoepca/pde-code-server:1.0.0 -c "echo amd64-shell-ok"'
```

The shell test should print `amd64-shell-ok`. It downloads the image if it is
not already present. Recheck emulation after restarting or recreating Minikube
and repeat the setup if necessary. Emulated workloads run more slowly than
native ARM64 workloads.

### Start the module

Run the _Mastering Earth Observation Application Packaging with CWL_ module on minikube with:

```
cd mastering-app-package
skaffold dev
```

Wait for the deployment to stabilize and then open your browser on the link
printed, usually http://127.0.0.1:8000. Initial setup downloads extensions and
Python packages and can take several minutes, especially under emulation.

### Troubleshooting startup

Inspect storage, pods, and initialization logs:

```sh
kubectl get pvc,pods -n eoap-mastering-app-package
kubectl describe pvc -n eoap-mastering-app-package
kubectl logs -n eoap-mastering-app-package deployment/code-server-deployment -c init-file-on-volume -f
```

- **PVC Pending / `storageclass.storage.k8s.io "hostpath" not found`:** complete
  the storage setup above. Existing bound claims retain their original class;
  changing `skaffold.yaml` does not migrate them. Do not delete bound claims to
  change class without preserving their data: the reclaim policy is `Delete`.
- **`Insufficient memory`:** the module requests 2 GiB for code-server, and the
  node also needs memory for Kubernetes, LocalStack, and processing jobs. Check
  allocations with `kubectl describe node minikube`. To increase the VM memory,
  run `minikube stop` followed by `minikube start --memory=8192` if your Mac has
  enough available RAM. This interrupts the cluster; recheck emulation afterward.
- **`exec /usr/bin/sh: exec format error`:** complete the AMD64 emulation setup
  and shell test above. Kubernetes retries the failed init container automatically.
- **`Init:0/1`:** inspect the init logs above. This can indicate normal package
  installation; it does not itself mean the PVC is waiting.
- **LocalStack auth-token notice:** the Helm chart can print this notice even
  when the pinned Community image `localstack/localstack:4.14.0` is healthy.
  Check the pod status. The pin avoids the authentication requirement introduced
  in [LocalStack 2026.03](https://blog.localstack.cloud/localstack-for-aws-release-2026-03-0/).
  If logs show license activation failure and exit code 55, verify the deployed
  image matches the pin in `mastering-app-package/skaffold.yaml`.

The typical output is: 

```
No tags generated
Starting deploy...
Helm release eoap-mastering-app-package not installed. Installing...
NAME: eoap-mastering-app-package
LAST DEPLOYED: Mon Oct 14 12:20:47 2024
NAMESPACE: eoap-mastering-app-package
STATUS: deployed
REVISION: 1
TEST SUITE: None
Helm release eoap-mastering-app-package-localstack not installed. Installing...
NAME: eoap-mastering-app-package-localstack
LAST DEPLOYED: Mon Oct 14 12:20:49 2024
NAMESPACE: eoap-mastering-app-package
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace "eoap-mastering-app-package" -l "app.kubernetes.io/name=localstack,app.kubernetes.io/instance=eoap-mastering-app-package-localstack" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace "eoap-mastering-app-package" $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace "eoap-mastering-app-package" port-forward $POD_NAME 8080:$CONTAINER_PORT
Waiting for deployments to stabilize...
 - eoap-mastering-app-package:deployment/code-server-deployment: waiting for init container init-file-on-volume to complete
    - eoap-mastering-app-package:pod/code-server-deployment-7f8865cd65-zkqnv: waiting for init container init-file-on-volume to complete
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] + cd /workspace
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] + git clone https://github.com/eoap/mastering-app-package.git
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] Cloning into 'mastering-app-package'...
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] + code-server --install-extension ms-python.python
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] [2024-10-14T10:20:50.244Z] info  Wrote default config file to /workspace/.config/code-server/config.yaml
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] Installing extensions...
      > [code-server-deployment-7f8865cd65-zkqnv init-file-on-volume] Installing extension 'ms-python.python'...
 - eoap-mastering-app-package:deployment/eoap-mastering-app-package-localstack: Readiness probe failed: Get "http://10.244.11.216:4566/_localstack/health": dial tcp 10.244.11.216:4566: connect: connection refused
    - eoap-mastering-app-package:pod/eoap-mastering-app-package-localstack-579f879dff-h9plw: Readiness probe failed: Get "http://10.244.11.216:4566/_localstack/health": dial tcp 10.244.11.216:4566: connect: connection refused
 - eoap-mastering-app-package:deployment/eoap-mastering-app-package-localstack is ready. [1/2 deployment(s) still pending]
 - eoap-mastering-app-package:deployment/code-server-deployment is ready.
Deployments stabilized in 1 minute 9.074 seconds
Port forwarding service/code-server-service in namespace eoap-mastering-app-package, remote port 8080 -> http://127.0.0.1:8000
No artifacts found to watch
Press Ctrl+C to exit
Watching for changes...
```
