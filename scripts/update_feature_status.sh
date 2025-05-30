#!/bin/bash
#
# Can be used to enable or disable specific features in the backend.
#

set +x

FEATURE_STATUS=${1}
FEATURE=${2}
SYNAPSE_HOST=${3}

# Retrieve a personal access token for a Synapse admin user from AWS secrets manager
ACCESS_TOKEN=`aws secretsmanager get-secret-value --secret-id /synapse/admin-pat --query SecretString --output text`

set +x ; echo "${SYNAPSE_HOST}/repo/v1/admin/feature/${FEATURE}/status -> $FEATURE_STATUS"
set +x ; curl --fail-with-body -H Authorization:"Bearer ${ACCESS_TOKEN}" "${SYNAPSE_HOST}/repo/v1/admin/feature/${FEATURE}/status"
set +x ; curl --fail-with-body -H Authorization:"Bearer ${ACCESS_TOKEN}" -H 'Content-Type: application/json' -d "{\"enabled\":$FEATURE_STATUS }" -X POST "${SYNAPSE_HOST}/repo/v1/admin/feature/$FEATURE/status"
