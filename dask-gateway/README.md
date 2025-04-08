# Dask Gateway

This folder contains a skaffold configuration to deploy Dask Gateway and Code Server.

This deployment is used to run the e-learning module [Dask application package](https://github.com/eoap/dask-app-package)

## Usage

Use `skaffold` to deploy on minikube:

```
skaffold dev
```

You can also use a remote cluster with:

```
skaffold dev --default-repo <your container registry>
``` 

## Why the deployment is so long?

THe code server pod has an init container that installs several tools, code extensions and python packages and this takes time.