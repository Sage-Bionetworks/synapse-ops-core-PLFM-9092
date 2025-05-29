#!/bin/bash
#
# Automated masking/removal of a Synapse user account. Can be used for GDPR.
# After removing a user, insert the JSON object containing their profile into column K
# of the Synapse Deactivation Requests list:
# https://docs.google.com/spreadsheets/d/1OEmIaq5pSTZbkagYrAqBiemPdycwopZQo0uyST448Bs/edit#gid=0
#  and update the rest of the row.
#

USER_ID=${1}
SYNAPSE_HOST=${2}

# Retrieve a personal access token for a Synapse admin user from AWS secrets manager
ACCESS_TOKEN=`aws secretsmanager get-secret-value --secret-id /synapse/admin-pat --query SecretString --output text`

set +x
curl --fail-with-body -H "Authorization:Bearer $ACCESS_TOKEN" $SYNAPSE_HOST/repo/v1/user/$USER_ID/bundle?mask=0xFFFF
curl --fail-with-body -X POST -H "Authorization:Bearer $ACCESS_TOKEN" $SYNAPSE_HOST/repo/v1/admin/redact/user/$USER_ID
