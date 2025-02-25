cd /workspace

#temp
mkdir event-driven-with-argo
git clone https://github.com/eoap/event-driven-with-argo.git
cd event-driven-with-argo
git checkout develop

code-server --install-extension ms-python.python 
code-server --install-extension ms-toolsai.jupyter
ln -s /workspace/.local/share/code-server/extensions /workspace/extensions

mkdir -p /workspace/User/
echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

python -m venv /workspace/.venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/python -m pip install --no-cache-dir ipykernel requests pyyaml boto3==1.35.23 loguru redis
/workspace/.venv/bin/python -m ipykernel install --user --name zoo_env --display-name "Python (Event Driven with Argo)"

export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
aws s3 mb s3://results --endpoint-url=http://eoap-event-driven-localstack:4566
aws s3 mb s3://workflows --endpoint-url=http://eoap-event-driven-localstack:4566