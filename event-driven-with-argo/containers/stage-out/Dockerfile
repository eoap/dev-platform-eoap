FROM docker.io/library/python:3.12.15-bookworm@sha256:14a4933e6cef421424f7a66d89a3f4eafcbd0d90e0a822251f298e05132dc735

# Refresh the OS trust store before downloading Python packages.
RUN apt-get update && apt-get install -y --only-upgrade ca-certificates && \
    update-ca-certificates && rm -rf /var/lib/apt/lists/*

RUN apt update && apt install -y yq

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade "pip @ https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70" && \
    pip install --no-cache-dir --upgrade "certifi>=2026.10.19" && \
    pip install --no-cache-dir -r /code/requirements.txt

COPY . /code

RUN cd /code && python setup.py install 

RUN stage-out --help
