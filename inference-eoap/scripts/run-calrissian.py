"""Execute published inference CWL against the real staged catalog on Kubernetes."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--context', required=True)
parser.add_argument('--namespace', default='eoap-inference')
parser.add_argument('--package', type=Path, required=True)
args = parser.parse_args()
payload = {'package': args.package.read_text(),
           'run': '/calrissian/inference-release/' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}
code = '''
import json, os, sys, subprocess, yaml
from pathlib import Path
p = json.load(sys.stdin)
run = Path(p['run'])
run.mkdir(parents=True)
document = yaml.safe_load(p['package'])
assert document['cwlVersion'] == 'v1.2'
for tool in document.get('$graph', [document]):
    for group in ('requirements', 'hints'):
        docker = tool.get(group, {}).get('DockerRequirement')
        if docker:
            assert docker['dockerPull'].startswith('ghcr.io/eoap/inference-eoap/')
            assert '@sha256:' in docker['dockerPull']
(run/'inference.cwl').write_text(p['package'])
source = json.loads(Path('/workspace/inference-eoap/runs/results.json').read_text())
catalog = Path(source['stac_catalog']['path'])
assert (catalog/'catalog.json').is_file()
(run/'job.json').write_text(json.dumps({'item': {'class': 'Directory', 'path': str(catalog)}}))
with (run/'outputs.json').open('w') as outputs, (run/'execution.log').open('w') as log:
    result = subprocess.run(['/opt/calrissian-venv/bin/calrissian', '--max-ram', '20G',
        '--max-cores', '4', '--pod-serviceaccount', 'calrissian-sa',
        '--pod-nodeselectors', '/etc/calrissian/pod-node-selector.yaml',
        '--outdir', str(run/'results'), '--tmp-outdir-prefix', str(run/'tmp')+'/',
        '--tool-logs-basepath', str(run/'logs'), '--usage-report', str(run/'usage.json'),
        str(run/'inference.cwl'), str(run/'job.json')], stdout=outputs, stderr=log,
        env={**os.environ, 'CWLTOOL_OPTIONS': ''})
if result.returncode:
    print((run/'execution.log').read_text()[-8000:])
    raise SystemExit(result.returncode)
outputs = json.loads((run/'outputs.json').read_text())
output = Path(outputs['stac_catalog']['path'])
assert (output/'catalog.json').is_file(), 'Empty output after failed main container'
assert list(output.rglob('classification.tif')), 'No classification raster'
Path('/workspace/inference-eoap/runs/calrissian-output.json').write_text(json.dumps(outputs))
print('Published Kubernetes inference passed. Evidence:', run)
'''
subprocess.run(['kubectl', '--context', args.context, '-n', args.namespace, 'exec', '-i',
                'deployment/code-server-deployment', '-c', 'code-server', '--',
                '/workspace/.venv/bin/python', '-c', code],
               input=json.dumps(payload), text=True, check=True)
