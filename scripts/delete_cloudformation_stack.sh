#!/bin/bash
#
# Deletes a Cloudformation stack - typically a synapse shared resources stack.
#

set +x

STACK_NAME=${1}

export AWS_DEFAULT_REGION=us-east-1
aws cloudformation delete-stack --stack-name ${STACK_NAME}
