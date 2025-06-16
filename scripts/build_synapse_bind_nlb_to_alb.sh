#!/bin/bash
#
# Binds NLBs to ALBs
#

set +x

# dev, staging or prod
STACK=${1}

# For instance 440 for Beanstalk number 12, string would be '440-12'
REPO_PROD_INSTANCE_AND_VERSION=${2}
PORTAL_PROD_INSTANCE_AND_VERSION=${3}
REPO_STAGING_INSTANCE_AND_VERSION=${4}
PORTAL_STAGING_INSTANCE_AND_VERSION=${5}
REPO_TEST_INSTANCE_AND_VERSION=${6}
PORTAL_TEST_INSTANCE_AND_VERSION=${7}

# Folder containing source code
SRC_PATH=${8}

# $(hostname repo 440-12) returns repo-prod-440-12
# $(hostname repo none) returns none
# $(hostname repo "") returns none
hostname() {
if [[ -z ${2} || none == ${2} ]]; then
    echo none
else
    echo ${1}-prod-${2}
fi
}

cd $SRC_PATH

mvn clean install

if [[ 'prod' == $STACK ]]; then
export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=${STACK}"\
" -Dorg.sagebionetworks.bind.record.to.stack.csv=\
repoprod.prod.sagebase.org->$(hostname repo $REPO_PROD_INSTANCE_AND_VERSION),\
www.synapse.org->$(hostname portal $PORTAL_PROD_INSTANCE_AND_VERSION),\
repostaging.prod.sagebase.org->$(hostname repo $REPO_STAGING_INSTANCE_AND_VERSION),\
staging.synapse.org->$(hostname portal $PORTAL_STAGING_INSTANCE_AND_VERSION),\
repotst.prod.sagebase.org->$(hostname repo $REPO_TEST_INSTANCE_AND_VERSION),\
tst.synapse.org->$(hostname portal $PORTAL_TEST_INSTANCE_AND_VERSION)"
else
export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=${STACK}"\
" -Dorg.sagebionetworks.bind.record.to.stack.csv=\
repo.prod.dev.sagebase.org->$(hostname repo $REPO_PROD_INSTANCE_AND_VERSION),\
portal.prod.dev.sagebase.org->$(hostname portal $PORTAL_PROD_INSTANCE_AND_VERSION),\
repos.staging.dev.sagebase.org->$(hostname repo $REPO_STAGING_INSTANCE_AND_VERSION),\
portal.staging.dev.sagebase.org->$(hostname portal $PORTAL_STAGING_INSTANCE_AND_VERSION),\
repotst.prod.sagebase.org->none,\
portal.tst.dev.sagebase.org->none"
fi

java -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.template.nlb.BindNetworkLoadBalancersMain
