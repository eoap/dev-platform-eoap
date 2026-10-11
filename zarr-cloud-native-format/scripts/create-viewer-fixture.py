"""Generate two local raster dates and publish output from the real module writer."""

from pathlib import Path
from datetime import datetime, timezone
import numpy as np
import rasterio
from rasterio.transform import from_origin
import pystac
from pystac.item_assets import ItemAssetDefinition

root = Path("/workspace/zarr-cloud-native-format/titiler-runs/smoke")
root.mkdir(parents=True, exist_ok=True)
from rasterio.warp import transform_bounds

bounds = list(
    transform_bounds("EPSG:32633", "EPSG:4326", 300000, 4993600, 306400, 5000000)
)
west, south, east, north = bounds
geometry = {
    "type": "Polygon",
    "coordinates": [
        [[west, south], [east, south], [east, north], [west, north], [west, south]]
    ],
}
catalog = pystac.Catalog("fixture", "Local inputs for the actual module writer")
collection = pystac.Collection(
    "water-bodies",
    "Viewer validation",
    pystac.Extent(
        pystac.SpatialExtent([bounds]),
        pystac.TemporalExtent(
            [
                [
                    datetime(2024, 1, 1, tzinfo=timezone.utc),
                    datetime(2024, 1, 2, tzinfo=timezone.utc),
                ]
            ]
        ),
    ),
)
collection.item_assets = {
    name: ItemAssetDefinition(
        {"type": "image/tiff; application=geotiff", "roles": ["data"], "title": name}
    )
    for name in ("ndwi", "water-bodies")
}
collection.extra_fields["renders"] = {
    "ndwi": {"assets": ["ndwi"], "rescale": [[-1, 1]], "colormap_name": "viridis"}
}
catalog.add_child(collection)
for day in (1, 2):
    path = root / f"input-{day}.tif"
    data = np.linspace(-0.8, 0.8, 4096, dtype="float32").reshape(64, 64) * (
        1 if day == 1 else -1
    )
    transform = from_origin(300000, 5000000, 100, 100)
    with rasterio.open(
        path,
        "w",
        driver="GTiff",
        width=64,
        height=64,
        count=1,
        dtype="float32",
        crs="EPSG:32633",
        transform=transform,
        nodata=-9999,
    ) as dst:
        dst.write(data, 1)
    item = pystac.Item(
        f"day-{day}",
        geometry,
        bounds,
        datetime(2024, 1, day, tzinfo=timezone.utc),
        {
            "proj:code": "EPSG:32633",
            "proj:shape": [64, 64],
            "proj:transform": list(transform)[:6],
        },
    )
    item.add_asset(
        "ndwi",
        pystac.Asset(
            str(path),
            media_type=pystac.MediaType.GEOTIFF,
            roles=["data"],
            extra_fields={"raster:bands": [{"data_type": "float32", "nodata": -9999}]},
        ),
    )
    mask_path = root / f"mask-{day}.tif"
    with rasterio.open(
        mask_path,
        "w",
        driver="GTiff",
        width=64,
        height=64,
        count=1,
        dtype="uint8",
        crs="EPSG:32633",
        transform=transform,
        nodata=255,
    ) as dst:
        dst.write((data > 0).astype("uint8"), 1)
    item.add_asset(
        "water-bodies",
        pystac.Asset(
            str(mask_path),
            media_type=pystac.MediaType.GEOTIFF,
            roles=["data"],
            extra_fields={"raster:bands": [{"data_type": "uint8", "nodata": 255}]},
        ),
    )
    collection.add_item(item)
catalog.normalize_and_save(
    str(root / "input"), catalog_type=pystac.CatalogType.SELF_CONTAINED
)
(root / "output").mkdir(exist_ok=True)

import subprocess

venv = Path("/workspace/.venv/bin")
subprocess.run(
    [
        str(venv / "stac-zarr"),
        "--stac-catalog",
        str(root / "input"),
        "--resolution",
        "100",
        "--overview-levels",
        "2",
    ],
    cwd=root / "output",
    check=True,
)
subprocess.run(
    [
        str(venv / "python"),
        "/workspace/zarr-cloud-native-format/scripts/publish-titiler-store.py",
        "--data-root",
        str(root / "output"),
    ],
    check=True,
)
