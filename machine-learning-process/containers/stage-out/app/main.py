""" Main module for the application. """
import os
import shutil

import boto3
import botocore
import click
import pystac
from botocore.client import Config
from loguru import logger
from pystac.stac_io import StacIO
import sys
from app.stac import CustomStacIO, upload_file_with_chunk_size
from app.usersettings import UserSettings


@click.command()
@click.option(
    "--stac-catalog", help="Local path to a folder containing catalog.json STAC Catalog", required=True
)
@click.option("--user-settings", help="S3 user settings", required=True)
@click.option("--bucket", "bucket", help="S3 bucket", required=True)
@click.option("--subfolder", "subfolder", help="S3 subfolder", required=True)
def main(stac_catalog, user_settings, bucket, subfolder):
    user_settings_config = UserSettings.from_file(user_settings)

    s3_settings = user_settings_config.get_s3_settings(f"s3://{bucket}/{subfolder}")

    if not s3_settings:
        raise ValueError("No S3 settings found for this bucket")

    # set the environment variables for S3 from the user settings
    os.environ["aws_access_key_id"] = s3_settings["aws_access_key_id"]
    os.environ["aws_secret_access_key"] = s3_settings["aws_secret_access_key"]
    os.environ["aws_region_name"] = s3_settings["region_name"]
    os.environ["aws_endpoint_url"] = s3_settings["endpoint_url"]

    client = boto3.client(
        "s3",
        **s3_settings,
        config=Config(s3={"addressing_style": "path", "signature_version": "s3v4"}),
    )

    shutil.copytree(stac_catalog, "/tmp/catalog")
    cat = pystac.read_file(os.path.join("/tmp/catalog", "catalog.json"))

    StacIO.set_default(CustomStacIO)

    for item in cat.get_items():
        for key, asset in item.get_assets().items():
            s3_path = os.path.normpath(
                os.path.join(os.path.join(subfolder, item.id, asset.href))
            )
            logger.info(f"upload {asset.href} to s3://{bucket}/{s3_path}")

            upload_file_with_chunk_size(
                client,
                asset.get_absolute_href(),
                bucket,
                s3_path
                )
            
            asset.href = f"s3://{bucket}/{s3_path}"
            item.add_asset(key, asset)

    cat.normalize_hrefs(f"s3://{bucket}/{subfolder}")

    for item in cat.get_items():
        # upload item to S3
        logger.info(f"upload {item.id} to s3://{bucket}/{subfolder}")
        for index, link in enumerate(item.links):
            if link.rel in ["collection"]:
                logger.info("saving collection.json")
                collection = link.target
                collection.links = []
                pystac.write_file(link.target, dest_href="./collection.json")
                item.links.pop(index) 
                item.set_collection(None)
            if link.rel in ["root"]:
                item.links.pop(index)
        pystac.write_file(item, item.get_self_href())

    # upload catalog to S3
    logger.info(f"upload catalog.json to s3://{bucket}/{subfolder}")
    for index, link in enumerate(cat.links):
        if link.rel in ["root", "collection"]:
            cat.links.pop(index) 
    pystac.write_file(cat, cat.get_self_href())

    logger.info("Done!")

    print(f"s3://{bucket}/{subfolder}/catalog.json", file=sys.stdout)
if __name__ == "__main__":
    main()
