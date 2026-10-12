# Argo STAC stage-out helper

This helper preserves the Argo `stage-out --stac-catalog --user-settings
--bucket --subfolder` interface. It builds a Python 3.12 wheel with Hatch and
installs hash-locked dependencies in a non-root Rocky 10.1 runtime.

```sh
hatch run dev:check
hatch run test:test
docker build -t stageout .
docker run --rm stageout stage-out --help
```

The development environment bootstraps its hash lock explicitly before quality
checks or tests. The runtime removes venv pip after installation and `pip check`.
The original JSON S3 user-settings layout remains supported. Credentials are
never printed. Source assets are copied into the requested S3 prefix, including
when their input hrefs are absolute; Item geometry, bbox and timestamp are
preserved. Temporary catalogs use a unique temporary directory.

The old setup.py/setup.cfg files are superseded by pyproject.toml. Version 0.3.4
retains the previous setup.cfg metadata; no release has been published by this
migration. License selection is pending because this checkout contains no
license declaration. Resolve it and validate the full Argo workflow before
release promotion.
