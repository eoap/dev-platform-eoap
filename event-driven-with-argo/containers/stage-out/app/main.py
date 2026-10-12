"""Main module for the application."""

import os
import shutil
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

import boto3
import click
import pystac
from botocore.client import Config
from loguru import logger
from pystac.stac_io import StacIO

from app.stac import CustomStacIO, upload_file_with_chunk_size
from app.usersettings import UserSettings


def publish_item(item: pystac.Item) -> None:
    """Publish an Item while retaining the legacy collection-link handling."""
    for link in list(item.links):
        if link.rel == "collection":
            link.resolve_stac_object()
            collection = link.target
            if not isinstance(collection, pystac.Collection):
                raise ValueError("Collection link must resolve to a Collection")
            collection.links = []
            pystac.write_file(collection, dest_href="./collection.json")
            item.set_collection(None)
        elif link.rel == "root":
            item.links.remove(link)
    pystac.write_file(item, dest_href=item.get_self_href())


@click.command()
@click.option(
    "--stac-catalog",
    help="Local path to a folder containing catalog.json STAC Catalog",
    required=True,
)
@click.option("--user-settings", help="S3 user settings", required=True)
@click.option("--bucket", "bucket", help="S3 bucket", required=True)
@click.option("--subfolder", "subfolder", help="S3 subfolder", required=True)
def main(stac_catalog: str, user_settings: str, bucket: str, subfolder: str) -> None:
    user_settings_config = UserSettings.from_file(user_settings)

    s3_settings = user_settings_config.get_s3_settings(f"s3://{bucket}/{subfolder}")

    if not s3_settings:
        raise ValueError("No S3 settings found for this bucket")

    # set the environment variables for S3 from the user settings
    os.environ["AWS_ACCESS_KEY_ID"] = s3_settings["aws_access_key_id"]
    os.environ["AWS_SECRET_ACCESS_KEY"] = s3_settings["aws_secret_access_key"]
    os.environ["AWS_REGION_NAME"] = s3_settings["region_name"]
    os.environ["AWS_ENDPOINT_URL"] = s3_settings["endpoint_url"]

    client = boto3.client(
        "s3",
        **s3_settings,
        config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
    )

    with TemporaryDirectory(prefix="eoap-stage-out-") as temporary:
        local_catalog = Path(temporary) / "catalog"
        shutil.copytree(stac_catalog, local_catalog)
        cat = pystac.read_file(str(local_catalog / "catalog.json"))

        if not isinstance(cat, pystac.Catalog):
            raise ValueError("Stage-out requires a STAC Catalog or Collection")

        StacIO.set_default(CustomStacIO)

        for item in cat.get_items():
            for key, asset in item.get_assets().items():
                s3_path = os.path.normpath(
                    os.path.join(subfolder, item.id, key, os.path.basename(asset.href))
                )
                logger.info(f"upload {asset.href} to s3://{bucket}/{s3_path}")

                href = asset.get_absolute_href()
                if href is None:
                    raise ValueError("Asset does not have a resolvable href")
                upload_file_with_chunk_size(client, href, bucket, s3_path)

                asset.href = f"s3://{bucket}/{s3_path}"
                item.add_asset(key, asset)

        cat.normalize_hrefs(f"s3://{bucket}/{subfolder}")

        for item in cat.get_items():
            publish_item(item)
        cat.links = [link for link in cat.links if link.rel not in ("root", "collection")]
        pystac.write_file(cat, dest_href=cat.get_self_href())

    logger.info("Done!")

    print(f"s3://{bucket}/{subfolder}/catalog.json", file=sys.stdout)


if __name__ == "__main__":
    main()
