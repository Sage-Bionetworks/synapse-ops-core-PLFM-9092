#!/bin/bash
#
# Binds NLBs to ALBs
#

set +x

# dev, staging or prod
STACK=${1}

# For instance 440
# Beanstalk number 12
# expected '440-12'
REPO_INSTANCE_AND_VERSION=${2}

# For instance 440
# Beanstalk number 12
# expected '440-12'
PORTAL_INSTANCE_AND_VERSION=${3}

# Folder containing source code
PATH=${4}

cd $PATH

mvn clean install

export CMD_PROPS=\
" -Dorg.sagebionetworks.stack=${STACK}"\
" -Dorg.sagebionetworks.bind.record.to.stack.csv=\
repoprod.prod.sagebase.org->repo-prod-$REPO_INSTANCE_AND_VERSION,\
www.synapse.org->portal-prod-$PORTAL_INSTANCE_AND_VERSION,\
repostaging.prod.sagebase.org->none,\
staging.synapse.org->none,\
repotst.prod.sagebase.org->none,\
tst.synapse.org->none"

java -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar $CMD_PROPS org.sagebionetworks.template.nlb.BindNetworkLoadBalancersMain
