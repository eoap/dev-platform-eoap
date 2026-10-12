"""Write STAC JSON and assets to configured S3 storage."""

from __future__ import annotations

import os
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.parse import urlparse

import boto3
from boto3.s3.transfer import TransferConfig
from botocore.client import Config
from pystac import Link
from pystac.stac_io import DefaultStacIO

if TYPE_CHECKING:
    from mypy_boto3_s3 import S3Client
    from pystac.link import HREF


class CustomStacIO(DefaultStacIO):
    """Retain local IO and add authenticated S3 writes."""

    def write_text(self, dest: HREF, txt: str, *args: object, **kwargs: object) -> None:
        href = dest.get_href() if isinstance(dest, Link) else os.fspath(dest)
        parsed = urlparse(href)
        if parsed.scheme != "s3":
            super().write_text(dest, txt, *args, **kwargs)
            return
        client = boto3.client(
            "s3",
            aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
            aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
            region_name=os.environ["AWS_REGION_NAME"],
            endpoint_url=os.environ["AWS_ENDPOINT_URL"],
            config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
        )
        client.put_object(
            Body=txt.encode("UTF-8"),
            Bucket=parsed.netloc,
            Key=parsed.path[1:],
            ContentType="application/geo+json",
        )


def upload_file_with_chunk_size(
    client: S3Client,
    file_path: str,
    bucket_name: str,
    s3_key: str,
    max_chunks: int = 1000,
    default_chunk_size_mb: int = 25,
) -> None:
    """Upload within the multipart minimum and configured part-count limit."""
    if max_chunks <= 0 or default_chunk_size_mb <= 0:
        raise ValueError("Multipart limits must be positive")
    size = Path(file_path).stat().st_size
    chunk = max(
        5 * 1024 * 1024, default_chunk_size_mb * 1024 * 1024, (size + max_chunks - 1) // max_chunks
    )
    client.upload_file(
        Filename=file_path,
        Bucket=bucket_name,
        Key=s3_key,
        Config=TransferConfig(multipart_chunksize=chunk),
    )
