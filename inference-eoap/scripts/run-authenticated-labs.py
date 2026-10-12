"""Run real CDSE S3 notebooks; credentials travel over exec stdin, never argv."""
import argparse
import json
from pathlib import Path
import shlex
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--context', required=True)
parser.add_argument('--namespace', default='eoap-inference')
parser.add_argument('--env-file', type=Path, required=True)
parser.add_argument('--timeout', default='1800')
args = parser.parse_args()
values = {}
for line in args.env_file.read_text().splitlines():
    tokens = shlex.split(line, comments=True)
    if tokens and tokens[0] == 'export':
        tokens = tokens[1:]
    if len(tokens) == 1 and '=' in tokens[0]:
        key, value = tokens[0].split('=', 1)
        values[key] = value
credentials = {}
for name, target in [('AWS_ACCESS_KEY_ID', 'CDSE_S3_ACCESS_KEY'),
                     ('AWS_SECRET_ACCESS_KEY', 'CDSE_S3_SECRET_KEY')]:
    if not values.get(name):
        parser.error(f'{args.env_file} must contain {name}')
    credentials[target] = values[name]
credentials['EOAP_INFERENCE_LOCAL_FIXTURE'] = '0'
runner = Path(__file__).resolve().parents[2] / 'mastering-app-package/scripts/run-practice-labs.py'
bootstrap = '''
import json, sys, os, nbformat
p = json.load(sys.stdin)
os.environ.update(p["env"])
sys.argv = p["args"]
secrets = [p["env"][key] for key in ("CDSE_S3_ACCESS_KEY", "CDSE_S3_SECRET_KEY")]
def redact(text):
    for secret in secrets:
        text = text.replace(secret, "[REDACTED]")
    return text
class RedactedStream:
    def __init__(self, stream): self.stream = stream
    def write(self, text): return self.stream.write(redact(text))
    def flush(self): return self.stream.flush()
sys.stdout = RedactedStream(sys.stdout)
sys.stderr = RedactedStream(sys.stderr)
original_write = nbformat.write
def safe_write(notebook, target, *args, **kwargs):
    clean = nbformat.reads(redact(nbformat.writes(notebook)), as_version=4)
    return original_write(clean, target, *args, **kwargs)
nbformat.write = safe_write
exec(compile(p["script"], "run-practice-labs.py", "exec"))
'''
for lab in ['Application steps', 'Container.ipynb', 'CommandLineTool.ipynb',
            'Workflow.ipynb', 'Execution-scenario.ipynb']:
    payload = {'env': credentials, 'script': runner.read_text(),
               'args': ['run-practice-labs.py', '--workspace', '/workspace/inference-eoap',
                        '--python-kernel', 'inference_env', '--notebooks-dir', 'practice-labs',
                        '--lab', lab, '--timeout', args.timeout, '--list', 'false']}
    subprocess.run(['kubectl', '--context', args.context, '-n', args.namespace, 'exec', '-i',
                    'deployment/code-server-deployment', '-c', 'code-server', '--',
                    '/opt/conda/bin/python', '-c', bootstrap], input=json.dumps(payload),
                   text=True, check=True)
