import os
from urllib.parse import urlparse

import boto3
import botocore
from botocore.client import Config
from pystac.stac_io import DefaultStacIO


class CustomStacIO(DefaultStacIO):
    """Custom STAC IO class that uses boto3 to read from S3."""

    def __init__(self):
        self.session = botocore.session.Session()

    def write_text(self, dest, txt, *args, **kwargs):
        self.s3_client = self.session.create_client(
            service_name="s3",
            use_ssl=True,
            aws_access_key_id=os.environ["aws_access_key_id"],
            aws_secret_access_key=os.environ["aws_secret_access_key"],
            region_name=os.environ["aws_region_name"],
            endpoint_url=os.environ["aws_endpoint_url"],
            config=Config(s3={"addressing_style": "path", "signature_version": "s3v4"}),
        )

        parsed = urlparse(dest)
        if parsed.scheme == "s3":
            self.s3_client.put_object(
                Body=txt.encode("UTF-8"),
                Bucket=parsed.netloc,
                Key=parsed.path[1:],
                ContentType="application/geo+json",
            )
        else:
            super().write_text(dest, txt, *args, **kwargs)

import boto3
from boto3.s3.transfer import TransferConfig
import os

import boto3
import os
import shutil
import logging
from boto3.s3.transfer import TransferConfig
from botocore.client import Config
from pystac import StacIO
import pystac

# Assuming CustomStacIO is already defined somewhere
# from your_custom_module import CustomStacIO

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def upload_file_with_chunk_size(client, file_path, bucket_name, s3_key, max_chunks=1000, default_chunk_size_mb=25):
    # Get the size of the file
    file_size = os.path.getsize(file_path)
    
    # Convert default chunk size from MB to bytes
    default_chunk_size = default_chunk_size_mb * 1024 * 1024
    
    # Calculate the optimal chunk size to ensure the number of chunks does not exceed max_chunks
    optimal_chunk_size = min(default_chunk_size, file_size // max_chunks + 1)
    
    # Configure the transfer settings
    config = TransferConfig(multipart_chunksize=optimal_chunk_size)

    # Upload the file
    client.upload_file(
        Filename=file_path,
        Bucket=bucket_name,
        Key=s3_key,
        Config=config
    )

