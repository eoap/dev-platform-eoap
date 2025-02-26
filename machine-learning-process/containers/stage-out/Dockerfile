FROM python:3.11

RUN apt update && apt install -y yq

WORKDIR /code

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir -r /code/requirements.txt

COPY . /code

RUN cd /code && python setup.py install 

RUN stage-out --help
