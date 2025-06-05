#!/bin/bash
#
# Build Synapse stack in new VPC.
#

set +x

# dev, staging or prod
STACK=${1}

# example: 544
INSTANCE=${2}

# example: 544.0
REPO_AND_WORKERS_VERSION=${3}

# example: 0
REPO_BEANSTALK_VERSION=${4}

# example: 544.0-4-gd18c3167f2
PORTAL_VERSION=${5}

# example: 0
PORTAL_BEANSTALK_VERSION=${6}

# example Blue
VPC_SUBNET_COLOR=${7}

# Folder containing source code
SRC_PATH=${8}

cd $SRC_PATH

mvn clean install

export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=$STACK"\
" -Dorg.sagebionetworks.instance=$INSTANCE"\
" -Dorg.sagebionetworks.beanstalk.version.repo=$REPO_AND_WORKERS_VERSION"\
" -Dorg.sagebionetworks.beanstalk.version.workers=$REPO_AND_WORKERS_VERSION"\
" -Dorg.sagebionetworks.beanstalk.version.portal=$PORTAL_VERSION"\
" -Dorg.sagebionetworks.vpc.subnet.color=$VPC_SUBNET_COLOR"\
" -Dorg.sagebionetworks.beanstalk.number.repo=$REPO_BEANSTALK_VERSION"\
" -Dorg.sagebionetworks.beanstalk.number.workers=0"\
" -Dorg.sagebionetworks.beanstalk.number.portal=$PORTAL_BEANSTALK_VERSION"\
" -Dorg.sagebionetworks.beanstalk.instance.type=m6g.large"\
" -Dorg.sagebionetworks.beanstalk.instance.memory=4096"\
" -Dorg.sagebionetworks.repo.rds.instance.class=db.r6g.2xlarge"\
" -Dorg.sagebionetworks.repo.rds.allocated.storage=512"\
" -Dorg.sagebionetworks.repo.rds.max.allocated.storage=1280"\
" -Dorg.sagebionetworks.repo.rds.storage.type=gp3"\
" -Dorg.sagebionetworks.repo.rds.iops=-1"\
" -Dorg.sagebionetworks.repo.rds.multi.az=true"\
" -Dorg.sagebionetworks.tables.rds.instance.count=1"\
" -Dorg.sagebionetworks.tables.rds.instance.class=db.r6g.4xlarge"\
" -Dorg.sagebionetworks.tables.rds.allocated.storage=3072"\
" -Dorg.sagebionetworks.tables.rds.max.allocated.storage=4096"\
" -Dorg.sagebionetworks.tables.rds.storage.type=gp3"\
" -Dorg.sagebionetworks.tables.rds.iops=-1"\
" -Dorg.sagebionetworks.beanstalk.max.instances.repo=12"\
" -Dorg.sagebionetworks.beanstalk.min.instances.repo=6"\
" -Dorg.sagebionetworks.beanstalk.ssl.arn.repo=arn:aws:acm:us-east-1:325565585839:certificate/a53c76a0-c54b-4538-81f0-028e28d8e812"\
" -Dorg.sagebionetworks.route.53.hosted.zone.repo=prod.sagebase.org"\
" -Dorg.sagebionetworks.beanstalk.max.instances.workers=12"\
" -Dorg.sagebionetworks.beanstalk.min.instances.workers=8"\
" -Dorg.sagebionetworks.beanstalk.number.workers=0"\
" -Dorg.sagebionetworks.beanstalk.ssl.arn.workers=arn:aws:acm:us-east-1:325565585839:certificate/a53c76a0-c54b-4538-81f0-028e28d8e812"\
" -Dorg.sagebionetworks.route.53.hosted.zone.workers=prod.sagebase.org"\
" -Dorg.sagebionetworks.beanstalk.max.instances.portal=8"\
" -Dorg.sagebionetworks.beanstalk.min.instances.portal=3"\
" -Dorg.sagebionetworks.beanstalk.ssl.arn.portal=arn:aws:acm:us-east-1:325565585839:certificate/7c42c355-3d69-4537-a5e6-428212db646f"\
" -Dorg.sagebionetworks.route.53.hosted.zone.portal=synapse.org"\
" -Dorg.sagebionetworks.doi.datacite.enabled=true"\
" -Dorg.sagebionetworks.repositoryservice.endpoint.prod=https://repo-prod.prod.sagebase.org/repo/v1"\
" -Dorg.sagebionetworks.beanstalk.image.version.amazonlinux=5.5.0"\
" -Dorg.sagebionetworks.docs.deploy=false"\
" -Dorg.sagebionetworks.docs.source=dev.release.rest.doc.sagebase.org"\
" -Dorg.sagebionetworks.docs.destination=rest-docs.synapse.org/rest"\
" -Dorg.sagebionetworks.enable.rds.enhanced.monitoring=true"\
" -Dorg.sagebionetworks.cloudfront.keypair=K1ODM3BLJ5L7YV"\
" -Dorg.sagebionetworks.vpc.ops.export.prefix=us-east-1-synapse-ops-vpc-v2"

java -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.template.repo.RepositoryBuilderMain
