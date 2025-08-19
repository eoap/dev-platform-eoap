cd /workspace
    owner=parham-membari-terradue

    git clone https://github.com/$owner/ogc-api-processes-with-zoo.git
    
    code-server --install-extension ms-python.python 

    code-server --install-extension ms-toolsai.jupyter

    ln -s /workspace/.local/share/code-server/extensions /workspace/extensions


    mkdir -p /workspace/User/


    echo '{"workbench.colorTheme": "Visual Studio Dark"}' > /workspace/User/settings.json

    python -m venv /workspace/.venv

    source /workspace/.venv/bin/activate
    
    /workspace/.venv/bin/python -m pip install --no-cache-dir stactools ipykernel requests pyyaml pystac boto3==1.35.23 loguru

    /workspace/.venv/bin/python -m ipykernel install --user --name zoo_env --display-name "Python (ZOO-Project)"

    export AWS_DEFAULT_REGION="us-east-1"

    export AWS_ACCESS_KEY_ID="test"
    
    export AWS_SECRET_ACCESS_KEY="test"
    
    aws s3 mb s3://results --endpoint-url=http://eoap-zoo-project-localstack:4566
    
    VERSION=$(curl -s https://api.github.com/repos/$owner/ogc-api-processes-with-zoo/releases/latest | jq -r '.tag_name')
    curl -L -o "/workspace/ogc-api-processes-with-zoo/cwl-workflows/eoap-api-cli.cwl" \
        "https://github.com/$owner/ogc-api-processes-with-zoo/releases/download/${VERSION}/eoap-api-cli.${VERSION}.cwl"
    #rm /workspace/cwl-workflows/eoap-api-cli.cwl