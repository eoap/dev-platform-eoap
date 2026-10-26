#!/bin/bash

cd /workspace

git clone 'https://github.com/eoap/application-package-patterns.git'

code-server --install-extension ms-python.python --install-extension redhat.vscode-yaml --install-extension sbg-rabix.benten-cwl --install-extension ms-toolsai.jupyter

ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/

echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/pip install --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" || exit $?
/workspace/.venv/bin/pip install --upgrade "certifi>=2026.10.19" || exit $?
/workspace/.venv/bin/pip install --upgrade "uv>=0.13.4"
/workspace/.venv/bin/python -m uv pip install --no-cache-dir stactools tomlq ipykernel graphviz "cwl-loader>=0.6.0" "cwl2puml>=0.9.0" "eoap-cwlwrap>=0.13.0" "pillow" "plantuml" "graphviz"

export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

aws s3 mb s3://results --endpoint-url=http://eoap-application-package-patterns-localstack:4566

rm -f /workspace/.venv/bin/yq

# for calrissian (eoap-cwlwrap uses a recent version of cwltool)
/workspace/.venv/bin/python -m uv pip install cwltool==3.1.20240708091337

/workspace/.venv/bin/python -m ipykernel install --user --name "cwl-eoap" --display-name "Python (Application Package patterns)"

exit $?