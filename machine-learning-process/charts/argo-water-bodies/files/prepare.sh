#!/bin/bash
set -x

cat >/tmp/cwl_parameters.json <<EOL
{
    "stac_items": {{`{{inputs.parameters.items}}`}},
    "aoi": "{{`{{inputs.parameters.aoi}}`}}",
    "epsg": "{{`{{inputs.parameters.epsg}}`}}"
}
EOL

# copy the app-package.json to /tmp/cwl_workflow.json
cat /config/app-package.json > /tmp/cwl_workflow.json
sleep 1
    