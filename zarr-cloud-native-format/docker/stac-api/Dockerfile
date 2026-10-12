FROM python:3.12-slim
RUN pip install --no-cache-dir 'stac-fastapi-geoparquet[serve]==0.0.6' 'rustac==0.9.17' 'stac-fastapi-api==5.0.2' 'stac-fastapi-extensions==5.0.2' 'stac-fastapi-types==5.0.2' 'fastapi==0.115.8' 'starlette==0.45.3'
RUN python -c 'import rustac; rustac.DuckdbClient(extension_directory="/opt/duckdb")'
COPY app.py /app/app.py
WORKDIR /app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
