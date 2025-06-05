#!/bin/bash
#
# Migrate from prod stack to staging stack.
#
# TZ=US/Pacific
# H 21 * * 3-5
#


set +x

# dev or prod
STACK=${1}

# Folder containing source code
SRC_PATH=${2}

REMAIN_READ_ONLY_MODE=${3}

cd $SRC_PATH

mvn clean install

export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=$STACK"\
" -Dorg.sagebionetworks.max.threads=1"\
" -Dorg.sagebionetworks.worker.thread.timout.ms=120000000"\
" -Dorg.sagebionetworks.max.retries=1"\
" -Dorg.sagebionetworks.max.backup.batchsize=50000"\
" -Dorg.sagebionetworks.min.delta.rangesize=7500"\
" -Dorg.sagebionetworks.full.table.migration.threshold.percentage=0.5"\
" -Dorg.sagebionetworks.backup.alias.type=MIGRATION_TYPE_NAME"\
" -Dorg.sagebionetworks.delay.before.start.ms=30000"\
" -Dorg.sagebionetworks.include.full.table.checksum=false"\
" -Dorg.sagebionetworks.service.key=synapseadm"\
" -Dorg.sagebionetworks.remain.read.only.mode=${REMAIN_READ_ONLY_MODE}"

java -Xms256m -Xmx4g -cp ./target/migration-utility-1.3-419-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.migration.MigrationClientMain
