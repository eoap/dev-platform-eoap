# Dask 2.0.0 release preparation

- [x] Publish the typed-CWL feature and prepare review PR #11.
- [x] Retire legacy platform Dask image publication in favour of course acceptance CI.
- [x] Lock matching Python 3.12 notebook, application, scheduler and worker runtimes.
- [x] Validate standalone CWL v1.2, embedded types, quoted EPSG codes and metadata.
- [x] Pass six regressions and strict training/platform documentation builds.
- [x] Pass editor/S3 smoke and real Calrissian two-worker computation/disposal.
- [x] Pass both real EO notebook lessons and geographic/scientific asset checks.
- [x] Pass both typed scientific CWL cases and verify cluster disposal.
- [x] Complete acceptance from clean intended-release commit `98a5899` (later `dcda5c2` changes only CI).
- [x] Pass clean Kubernetes CI at `f428aed` and publish candidate `2.0.0-rc.69`.
- [x] Verify anonymous GHCR pulls and adopt the accepted published worker digest.
- [ ] Review and promote the accepted feature before explicit stable publication.

Acceptance is bounded to two cloudless acquisitions at 100 m and an explicit
1024-pixel EOPF window. Full-tile capacity and ARM64 are not accepted. Calrissian
can report a disposal sidecar's success after the main process fails; the CWL
outputs now reject a missing catalog and scientific acceptance validates all
assets. The generic cwl2oci parser still cannot load the mandatory Dask extension.
