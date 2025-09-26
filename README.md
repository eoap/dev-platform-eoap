# Development platform for Earth Observation Application Package training modules

## Requirements

Before you begin, make sure you have the following tools installed and set up on your local environment:

### Skaffold

Skaffold is used to build, push, and deploy your application to Kubernetes. 

You can install it by following the instructions [here](https://skaffold.dev/docs/install/#standalone-binary).

On MacOS you can use `brew install skaffold`

### Helm

Helm is a package manager for Kubernetes, enabling you to manage Kubernetes applications easily. 

You can install it by following the steps [here](https://helm.sh/docs/intro/install/).

On MacOS you can use `brew install helm`


### Minikube

Minikube runs a local Kubernetes cluster, ideal for development and testing. 

#### Linux

You can install it by following the guide [here](https://minikube.sigs.k8s.io/docs/start) 

Then start your minikube instance with:

```
minikube start
```

#### MacOS

Install docker with:

```
brew install --cask docker
```

Start Docker Desktop (once) so the Docker daemon is available

```
open -a "Docker"
```

Install `kubectl` and `minikube`:

```
brew install kubectl minikube
```

Start minikube with:

```
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=40g
```

Note: adapt the resources if needed


### Helm repositories

```
helm repo add localstack https://localstack.github.io/helm-charts
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

Run the _Mastering Earth Observation Application Packaging with CWL_ module on minikube with:

```
cd mastering-app-package
skaffold dev
```

Wait for the deployment to stablize (1-2 minutes) and then open your browser on the link printed, usually http://127.0.0.1:8000.

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