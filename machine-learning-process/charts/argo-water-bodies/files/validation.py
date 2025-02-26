import sys
import json
import ast
import jsonschema
from jsonschema import validate

inputs_raw = """{{`{{inputs.parameters.inputs}}`}}"""

inputs = ast.literal_eval(inputs_raw)

# Load the JSON schema from a file
with open("/schema/input-schema.json", "r") as schema_file:
    schema = json.load(schema_file)

try:
    validate(instance=inputs, schema=schema)
    print("Input JSON is valid.")
except jsonschema.exceptions.ValidationError as err:
    print(f"Input JSON is invalid: {err.message}")
    sys.exit(2)