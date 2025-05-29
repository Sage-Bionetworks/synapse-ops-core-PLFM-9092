#!/bin/bash
#
# Removing quarantine status of user.
# Added a POST /admin/emailQuarantine/expire API that allows to remove an email 
# address from quarantine, the body of the request needs to contain an attribute 
# "email" which value is the email to be un-quarantined.
#
# Note that this will leave the record in the database but the expiration date 
# of the quarantined record will be updated to the current time 
# (effectively un-quarantining the email address).
#

set +x

EMAIL=${1}
SYNAPSE_HOST=${2}

# Retrieve a personal access token for a Synapse admin user from AWS secrets manager
ACCESS_TOKEN=`aws secretsmanager get-secret-value --secret-id /synapse/admin-pat --query SecretString --output text`

curl --fail-with-body -X POST -H "Authorization:Bearer $ACCESS_TOKEN" -H content-type:application/json -d "{\"email\":\"$EMAIL\"}" $SYNAPSE_HOST/repo/v1/admin/emailQuarantine/expire
