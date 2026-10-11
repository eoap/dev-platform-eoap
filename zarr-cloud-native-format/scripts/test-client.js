/* Exercise the actual client functions against both legacy and 0.12.2 keys. */
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const vm = require('vm');
const filename = process.argv[2] || path.resolve(__dirname, '../../../zarr-cloud-native-format/examples/titiler-eopf-client.html');
const html = fs.readFileSync(filename, 'utf8');
for (const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) new vm.Script(match[1]);
const parse = html.slice(html.indexOf('function parseMeasurementFromExpression'), html.indexOf('function getRenders'));
const normalize = html.slice(html.indexOf('function normalizeRenderDefinitions'), html.indexOf('async function loadMetadata'));
const resolve = new Function('measurementKeys', parse + normalize + '; return normalizeRenderDefinitions({ndwi:{expression:"/measurements:ndwi"}})[0].expression;');
assert.equal(resolve(['ndwi', 'water-bodies']), 'ndwi');
assert.equal(resolve(['/:ndwi']), '/:ndwi');
assert.equal(resolve(['/measurements:ndwi', 'ndwi']), '/measurements:ndwi');
assert.equal(resolve(['/a:ndwi', '/b:ndwi']), '/measurements:ndwi');
const route = html.slice(html.indexOf('function datasetRoute'), html.indexOf('function parseMeasurementFromExpression'));
const url = new Function('viewerConfig', 'apiBase', 'collectionId', 'itemId', route + '; return buildKeysUrl();');
assert.equal(url({assetId:'measurements'}, ()=>'http://localhost:8090/api', ()=>'water-bodies', ()=>'water-bodies'), 'http://localhost:8090/api/collections/water-bodies/items/water-bodies/assets/measurements/dataset/keys');
console.log('Client syntax, variable resolution and 0.12.2 asset route passed');
