#!/bin/bash
#
# This is the job used to verify an oauth client in procedure at
# https://sagebionetworks.jira.com/wiki/spaces/PLFM/pages/2361753659/Verifying+an+OAuth+client
#

CLIENT_ID=${1}
VERIFY_STATUS=${2}
SYNAPSE_HOST=${3}

# Retrieve a personal access token for a Synapse admin user from AWS secrets manager
ACCESS_TOKEN=`aws secretsmanager get-secret-value --secret-id /synapse/admin-pat --query SecretString --output text`

# Get the current ETAG for the given client
ETAG=$(curl --fail-with-body -H "Authorization:Bearer ${ACCESS_TOKEN}" -X GET "${SYNAPSE_HOST}/auth/v1/oauth2/client/${CLIENT_ID}" | sed "s/.*\"etag\":\"\([^\"]*\)\".*/\1/")
echo "${SYNAPSE_HOST}/repo/v1/admin/oauth2/client/${CLIENT_ID}/verified?status=${VERIFY_STATUS}&etag=${ETAG}"
curl --fail-with-body -i -H "Authorization:Bearer ${ACCESS_TOKEN}" -X PUT "${SYNAPSE_HOST}/repo/v1/admin/oauth2/client/${CLIENT_ID}/verified?status=${VERIFY_STATUS}&etag=${ETAG}"
