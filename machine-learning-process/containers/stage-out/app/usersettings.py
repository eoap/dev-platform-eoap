"""
This code defines a UserSettings class that has methods for reading JSON files,
matching regular expressions, and setting environment variables for an S3 service.
The set_s3_environment method sets environment variables for an S3 service based
on a given URL.
"""

import json
import os
import re
from typing import Dict


class UserSettings:
    """class for reading JSON files, matching regular expressions,
    and setting environment variables for an S3 service"""

    def __init__(self, settings: Dict):
        self.settings = settings

    @classmethod
    def from_file(cls, file_path):
        """create a UserSettings object from a JSON file"""
        return cls(cls.read_json_file(file_path))

    @staticmethod
    def read_json_file(file_path):
        """read a JSON file and return the contents as a dictionary"""
        with open(file_path, "r", encoding="utf-8") as stream:
            return json.load(stream)

    @staticmethod
    def match_regex(regex, string):
        """match a regular expression to a string and return the match object"""
        return re.search(regex, string)

    @staticmethod
    def set_s3_vars(s3_service):
        """set environment variables for an S3 service"""
        os.environ["AWS_ACCESS_KEY_ID"] = s3_service["AccessKey"]
        os.environ["AWS_SECRET_ACCESS_KEY"] = s3_service["SecretKey"]
        os.environ["AWS_DEFAULT_REGION"] = s3_service["Region"]
        os.environ["AWS_REGION"] = s3_service["Region"]
        os.environ["AWS_S3_ENDPOINT"] = s3_service["ServiceURL"]

    def set_s3_environment(self, url):
        """set environment variables for an S3 service based on a given URL"""
        for _, s3_service in self.settings["S3"]["Services"].items():
            if self.match_regex(s3_service["UrlPattern"], url):
                self.set_s3_vars(s3_service)
                break

    def get_s3_settings(self, url):
        """return S3 settings based on a given URL"""
        for _, s3_service in self.settings["S3"]["Services"].items():
            if self.match_regex(s3_service["UrlPattern"], url):
                return {
                    "region_name": s3_service["Region"],
                    "endpoint_url": s3_service["ServiceURL"],
                    "aws_access_key_id": s3_service["AccessKey"],
                    "aws_secret_access_key": s3_service["SecretKey"],
                }
        return None
