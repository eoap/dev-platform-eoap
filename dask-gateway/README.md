# Dask Gateway

This folder contains a skaffold configuration to deploy Dask Gateway and Code Server.

This deployment is used to run the e-learning module [Dask application package](https://github.com/eoap/dask-app-package)

## Usage

To deploy on minikube, use `skaffold` with one of the available profiles:

- `wrs-coverage`
- `eopf-sentinel-2`
- `cloudless-mosaic`

e.g.:

```
skaffold dev -p wrs-coverage
```

You can also use a remote cluster with:

```
skaffold dev --default-repo <your container registry>
``` 

## Using task

You can use [taskfile](https://taskfile.dev/) to start the skaffold deployment:

```console
task dask-gateway SKAFFOLD_PROFILE=eopf-sentinel-2
```

## Why the deployment is so long?

THe code server pod has an init container that installs several tools, code extensions and python packages and this takes time.