"""Check real inference outputs against staged rasters and the actual ONNX model."""
from pathlib import Path
import json
import numpy as np
import onnxruntime as ort
import pystac
import rasterio
from rasterio.windows import Window

root = Path('/workspace/inference-eoap')
results = json.loads((root / 'runs/results.json').read_text())
source = pystac.read_file(str(Path(results['stac_catalog']['path']) / 'catalog.json'))
item = next(source.get_items())
bands = [a for a in item.assets.values() if 'data' in (a.roles or [])]
assert len(bands) == 13, 'Expected all thirteen real L1C bands'
assert not item.id.startswith('local-'), 'Synthetic input cannot pass real acceptance'
red = item.assets['red'].get_absolute_href()
model_name = 'sentinel2_classification_trained_model_e50_9190.onnx'
packaged_model = root / 'src/eoap_inference/model' / model_name
legacy_model = root / 'tile-based-classification/command-line-tools/inference/model' / model_name
session = ort.InferenceSession(str(packaged_model if packaged_model.is_file() else legacy_model))
with rasterio.open(red) as reference:
    width, height = reference.width, reference.height
    x, y = ((width - 1) // 64) * 64, ((height - 1) // 64) * 64
    chip = np.zeros((1, 64, 64, 13), dtype=np.float32)
    for index, asset in enumerate(bands):
        with rasterio.open(asset.get_absolute_href()) as raster:
            assert raster.crs == reference.crs and raster.transform == reference.transform
            assert (raster.width, raster.height) == (width, height)
            pixels = raster.read(1, window=Window(x, y, width - x, height - y))
            chip[0, :pixels.shape[0], :pixels.shape[1], index] = pixels
    probabilities = session.run(None, {session.get_inputs()[0].name: chip})[0]
    expected_edge_class = int(np.argmax(probabilities[0]))
    outputs = list((root / 'runs').rglob('classification.tif'))
    calrissian_results = root / 'runs/calrissian-output.json'
    if calrissian_results.exists():
        result = json.loads(calrissian_results.read_text())
        outputs.extend(Path(result['stac_catalog']['path']).rglob('classification.tif'))
    assert outputs, 'No classification raster produced'
    for path in outputs:
        with rasterio.open(path) as raster:
            assert raster.crs == reference.crs and raster.transform == reference.transform
            assert raster.bounds == reference.bounds
            assert (raster.width, raster.height, raster.count) == (width, height, 1)
            for _, window in raster.block_windows(1):
                values = raster.read(1, window=window)
                assert np.all(values < probabilities.shape[-1]), 'Unexpected model class'
            edge = raster.read(1, window=Window(width - 1, height - 1, 1, 1))
            assert int(edge[0, 0]) == expected_edge_class, 'Last edge chip was not classified correctly'
        print(f'Validated {path}: {width}x{height}, original CRS/transform, class range and real-model edge prediction')
