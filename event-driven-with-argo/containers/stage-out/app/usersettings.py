"""Read the existing Argo S3 user-settings format without exposing credentials."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import TypedDict


class S3Service(TypedDict):
    UrlPattern: str
    AccessKey: str
    SecretKey: str
    Region: str
    ServiceURL: str


class S3Settings(TypedDict):
    aws_access_key_id: str
    aws_secret_access_key: str
    region_name: str
    endpoint_url: str


class UserSettings:
    """Select a configured S3 service using its published URL pattern."""

    def __init__(self, services: list[S3Service]) -> None:
        self.services = services

    @classmethod
    def from_file(cls, file_path: str) -> UserSettings:
        raw: object = json.loads(Path(file_path).read_text())
        if not isinstance(raw, dict) or not isinstance(raw.get("S3"), dict):
            raise ValueError("User settings require an S3 object")
        services = raw["S3"].get("Services")
        if not isinstance(services, dict):
            raise ValueError("S3 settings require a Services object")
        parsed = []
        for service in services.values():
            if not isinstance(service, dict):
                raise ValueError("S3 service must be an object")
            values = [
                service.get(k)
                for k in ("UrlPattern", "AccessKey", "SecretKey", "Region", "ServiceURL")
            ]
            if not all(isinstance(value, str) for value in values):
                raise ValueError("S3 service fields must be strings")
            parsed.append(
                S3Service(
                    UrlPattern=str(values[0]),
                    AccessKey=str(values[1]),
                    SecretKey=str(values[2]),
                    Region=str(values[3]),
                    ServiceURL=str(values[4]),
                )
            )
        return cls(parsed)

    def get_s3_settings(self, url: str) -> S3Settings | None:
        """Return boto3 connection parameters for the first matching service."""
        for service in self.services:
            if re.search(service["UrlPattern"], url):
                return S3Settings(
                    region_name=service["Region"],
                    endpoint_url=service["ServiceURL"],
                    aws_access_key_id=service["AccessKey"],
                    aws_secret_access_key=service["SecretKey"],
                )
        return None

    def set_s3_environment(self, url: str) -> None:
        """Expose the selected service to standard AWS clients."""
        settings = self.get_s3_settings(url)
        if settings is None:
            raise ValueError("No S3 settings found for this URL")
        os.environ.update(
            AWS_ACCESS_KEY_ID=settings["aws_access_key_id"],
            AWS_SECRET_ACCESS_KEY=settings["aws_secret_access_key"],
            AWS_DEFAULT_REGION=settings["region_name"],
            AWS_REGION=settings["region_name"],
            AWS_S3_ENDPOINT=settings["endpoint_url"],
        )
