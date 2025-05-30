#!/bin/bash
#
# Enable anonymous download, part of the SOP at
# https://sagebionetworks.jira.com/wiki/spaces/PLFM/pages/792231937/Configuring+Tables+to+Allow+Anonymous+View+Access .
#

set +x

Synapse_ID=${1}
SYNAPSE_HOST=${2}

# Retrieve a personal access token for a Synapse admin user from AWS secrets manager
ACCESS_TOKEN=`aws secretsmanager get-secret-value --secret-id /synapse/admin-pat --query SecretString --output text`

echo "$SYNAPSE_HOST/repo/v1/entity/${Synapse_ID}/datatype?type=OPEN_DATA"
set +x ; curl -i --fail-with-body  -H "Authorization:Bearer $ACCESS_TOKEN" -X PUT "$SYNAPSE_HOST/repo/v1/entity/${Synapse_ID}/datatype?type=OPEN_DATA"
