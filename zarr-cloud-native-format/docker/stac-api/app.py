"""Use image-bundled DuckDB extensions, avoiding downloads at pod startup."""

from rustac import DuckdbClient
from stac_fastapi.geoparquet.api import create

app = create(
    duckdb_client=DuckdbClient(
        extension_directory="/opt/duckdb", install_extensions=False
    )
).app
