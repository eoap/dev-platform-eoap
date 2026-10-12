"""Check service selection and multipart limits without using credentials."""

import json
from unittest.mock import Mock

import pytest

from app.stac import upload_file_with_chunk_size
from app.usersettings import UserSettings


def test_service_selection(tmp_path):
    path = tmp_path / "settings.json"
    path.write_text(
        json.dumps(
            {
                "S3": {
                    "Services": {
                        "local": {
                            "UrlPattern": "^s3://results/",
                            "AccessKey": "test",
                            "SecretKey": "test",
                            "Region": "us-east-1",
                            "ServiceURL": "http://localhost:8333",
                        }
                    }
                }
            }
        )
    )
    settings = UserSettings.from_file(str(path))
    selected = settings.get_s3_settings("s3://results/run")
    assert selected is not None
    assert selected["endpoint_url"] == "http://localhost:8333"
    assert settings.get_s3_settings("s3://other/run") is None


@pytest.mark.parametrize("document", [{}, {"S3": {}}, {"S3": {"Services": {"bad": {}}}}])
def test_invalid_settings_are_rejected(tmp_path, document):
    path = tmp_path / "settings.json"
    path.write_text(json.dumps(document))
    with pytest.raises(ValueError):
        UserSettings.from_file(str(path))


def test_multipart_count_and_minimum(tmp_path):
    path = tmp_path / "asset"
    with path.open("wb") as stream:
        stream.truncate(100 * 1024 * 1024)
    client = Mock()
    upload_file_with_chunk_size(client, str(path), "results", "asset", max_chunks=2)
    parameters = client.upload_file.call_args.kwargs
    assert parameters["Config"].multipart_chunksize >= 50 * 1024 * 1024
    assert parameters["Bucket"] == "results"


def test_invalid_multipart_limit(tmp_path):
    with pytest.raises(ValueError):
        upload_file_with_chunk_size(
            Mock(), str(tmp_path / "missing"), "results", "asset", max_chunks=0
        )
