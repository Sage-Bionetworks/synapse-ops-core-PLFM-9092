#!/bin/bash
#
# Submit a request for archiving unlinked file handles. Normally runs every 30 minutes
# between 12:00 AM and 06:59 AM, Tuesday through Thursday (Pacific Time):
# TZ=US/Pacific
# H/30 0-6 * * 2-4
#

set +x

# dev or prod
STACK=${1}

# prod.prod.sagebase.org
# staging.prod.sagebase.org
# dev.dev.sagebase.org
STACK_ENDPOINT_SUFFIX=${2}

# The job timeout in milliseconds
TIMEOUT_MILLIS=${3}


# The max number of files to archive
FILE_COUNT_LIMIT=${4}

# Folder containing source code
SRC_PATH=${5}

export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=${STACK}"\
" -Dorg.sagebionetworks.jobs.timeout=${TIMEOUT_MILLIS}"\
" -Dorg.sagebionetworks.jobs.endpoint.repo=https://repo-${STACK_ENDPOINT_SUFFIX}/repo/v1"\
" -Dorg.sagebionetworks.jobs.endpoint.auth=https://auth-${STACK_ENDPOINT_SUFFIX}/auth/v1"\
" -Dorg.sagebionetworks.jobs.endpoint.file=https://file-${STACK_ENDPOINT_SUFFIX}/file/v1"

cd $SRC_PATH

mvn clean install

java -Xms256m -Xmx512m -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.template.jobs.AsyncAdminJobExecutorMain \
"{ \"concreteType\": \"org.sagebionetworks.repo.model.file.FileHandleArchivalRequest\", \"limit\": ${FILE_COUNT_LIMIT} }"
