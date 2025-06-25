#!/bin/bash
#
# Build Synapse CDN WebACLs
#

set +x

# dev, staging or prod
STACK=${1}
SUBDOMAIN=${2}
CERTIFICATE_ARN=${3}

# Folder containing source code
SRC_PATH=${4}

cd $SRC_PATH

mvn clean install

CMD_PROPS=" -Dorg.sagebionetworks.stack=${STACK}"
CMD_PROPS+=" -Dorg.sagebionetworks.stack.instance.alias=${SUBDOMAIN}"
CMD_PROPS+=" -Dorg.sagebionetworks.beanstalk.ssl.arn.portal=${CERTIFICATE_ARN}"
export $CMD_PROPS

java $CMD_PROPS -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar org.sagebionetworks.template.cdn.webacl.CdnBuilderMain
