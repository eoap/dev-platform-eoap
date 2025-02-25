# stage-out


## For developers

Create a Python environment with, e.g. `mamba`:

```
mamba create -n env_stage_in python
mamba activate env_stage_in
```

```
pip install -r requirements.txt
```

## Container

Build the container with:

```
docker build -t stage-out .
```

Test the container with:

```
docker run --rm docker.io/library/stage-out stage-out --help
```

## CWL 

You can use a cwlrunner like `cwltool` to do a stage-in operation.

Requirement:

* a built container tagged `docker.io/library/stage-out:latest` 

```
cwltool stage-out.cwl --bucket iride-sentinel-2 --stac_catalog /data/work/iride-marketplace/stage-in/_ka1p9cp --subfolder pippo --usersettings usersettings.json
```

## Run tests

The unit tests can be run with:

`nose2`

TODO: add capture stdout in CWL