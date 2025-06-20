#!/bin/bash
#
# Build Synapse CDN WebACLs
#

set +x

# dev, staging or prod
STACK=${1}

# Folder containing source code
SRC_PATH=${2}

cd $SRC_PATH

mvn clean install

export CMD_PROPS = " -Dorg.sagebionetworks.stack=${STACK}"

java $CMD_PROPS -Xms256m -Xmx2g -cp ./target/stack-builder-0.2.0-SNAPSHOT-jar-with-dependencies.jar org.sagebionetworks.template.cdn.webacl.CdnWebAclBuilderMain
