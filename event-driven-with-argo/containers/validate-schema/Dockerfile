FROM docker.io/rockylinux/rockylinux:10.1-minimal@sha256:cfa2812ec7151c2be393cfe46e50cf59426373d12f03f4ffbdd56becb8195a65 AS builder
RUN microdnf -y update && microdnf -y install python3 python3-pip && microdnf clean all
WORKDIR /src
COPY requirements.txt /src/requirements.txt
RUN python3 -m pip download --only-binary=:all: --require-hashes -r requirements.txt -d /wheels

FROM docker.io/rockylinux/rockylinux:10.1-minimal@sha256:cfa2812ec7151c2be393cfe46e50cf59426373d12f03f4ffbdd56becb8195a65 AS runtime
RUN microdnf -y update && \
    microdnf -y install python3 python3-pip git jq libstdc++ sqlite-libs zlib libgomp expat && \
    microdnf clean all
ENV HOME=/home/neo
RUN /usr/sbin/groupadd -g 2000 neo && \
    /usr/sbin/useradd -u 2000 -g 2000 -m -d ${HOME} -s /sbin/nologin neo && \
    mkdir -p /app /work && chown -R 2000:2000 /app /work ${HOME}
USER neo
WORKDIR /app
ENV VIRTUAL_ENV=/app/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}:/usr/bin"
RUN python3 -c 'import sys; assert sys.version_info[:2] == (3, 12)' && python3 -m venv /app/venv
COPY --from=builder --chown=2000:2000 /wheels /app/wheels
COPY --chown=2000:2000 requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --no-index --find-links=/app/wheels --require-hashes -r /app/requirements.txt && \
    pip check && python -m pip uninstall --yes pip && \
    python -c 'from jsonschema import validate; validate({"value": 1}, {"type": "object"})' && \
    rm -rf /app/requirements.txt /app/wheels
ENTRYPOINT []
CMD ["python", "--version"]
