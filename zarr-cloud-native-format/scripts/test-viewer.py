"""HTTP acceptance checks against a published store, through the client proxy."""

import json
from urllib.request import urlopen
from urllib.parse import urlencode, urlsplit
import os

base = os.environ.get("VIEWER_URL", "http://titiler-eopf-client:8080").rstrip("/")
collection = os.environ.get("COLLECTION_ID", "water-bodies")
item = os.environ.get("ITEM_ID", collection)
route = f"{base}/api/collections/{collection}/items/{item}"


def get(url):
    with urlopen(url, timeout=120) as response:
        return response.read()


assert b"titiler-eopf-config.js" in get(base + "/")
assert b'"/api"' in get(base + "/titiler-eopf-config.js")
metadata = json.loads(get(f"{base}/data/{collection}/collection.json"))
keys = json.loads(get(route + "/dataset/keys"))
print("Dataset keys:", keys)
variable = next(key for key in keys if key.endswith(":ndwi"))
query = urlencode(
    {"variables": variable, "rescale": "-1,1", "colormap_name": "viridis", "bidx": 1}
)
tilejson = json.loads(get(route + "/WebMercatorQuad/tilejson.json?" + query))
tileurl = tilejson["tiles"][0]
assert urlsplit(tileurl).netloc == urlsplit(base).netloc, tileurl
assert "/api/" in tileurl, tileurl
bounds = tilejson["bounds"]
import math

lon, lat = (bounds[0] + bounds[2]) / 2, (bounds[1] + bounds[3]) / 2
z = 8
x = int((lon + 180) / 360 * 2**z)
y = int((1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * 2**z)
png = get(tileurl.replace("{z}", str(z)).replace("{x}", str(x)).replace("{y}", str(y)))
assert png.startswith(b"\x89PNG\r\n\x1a\n"), png[:100]
print(
    "Client, STAC metadata, dataset keys, public TileJSON URLs and rendered PNG passed"
)

from PIL import Image
from io import BytesIO

image = Image.open(BytesIO(png)).convert("RGBA")
assert image.getchannel("A").getextrema()[1] > 0, (
    "Rendered tile is completely transparent"
)
dates = metadata.get("summaries", {}).get("datetime", [])
if len(dates) > 1:
    images = []
    for date in (dates[0], dates[-1]):
        dated = json.loads(
            get(
                route
                + "/WebMercatorQuad/tilejson.json?"
                + urlencode(
                    {
                        "variables": variable,
                        "rescale": "-1,1",
                        "colormap_name": "viridis",
                        "sel": f"time=nearest::{date}",
                    }
                )
            )
        )
        url = (
            dated["tiles"][0]
            .replace("{z}", str(z))
            .replace("{x}", str(x))
            .replace("{y}", str(y))
        )
        data = get(url)
        assert data.startswith(b"\x89PNG\r\n\x1a\n")
        images.append(data)
    print(
        "Two time-selected PNG requests passed; distinct images:",
        images[0] != images[1],
    )
    if os.environ.get("EXPECT_DISTINCT_TIMES") == "1":
        assert images[0] != images[1], "Fixture dates must produce distinct images"

for key in keys:
    if key == variable:
        continue
    other = json.loads(
        get(
            route
            + "/WebMercatorQuad/tilejson.json?"
            + urlencode({"variables": key, "rescale": "0,1", "bidx": 1})
        )
    )
    tile = (
        other["tiles"][0]
        .replace("{z}", str(z))
        .replace("{x}", str(x))
        .replace("{y}", str(y))
    )
    assert get(tile).startswith(b"\x89PNG\r\n\x1a\n")
    print("Additional variable rendered:", key)
