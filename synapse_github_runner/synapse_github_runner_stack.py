import os
from pathlib import Path

from aws_cdk import (Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    CfnOutput,
    Duration,
    Tags)

import config as config
import aws_cdk.aws_certificatemanager as cm
import aws_cdk.aws_secretsmanager as sm
from constructs import Construct
from synapse_github_runner.get_latest_image import get_latest_image

from aws_cdk.aws_ecr_assets import Platform

def get_account_id(env: dict) -> str:
    return env.get("ACCOUNT_ID")

def get_region(env: dict) -> str:
    return env.get("AWS_DEFAULT_REGION")

def get_vpc_id(env: dict) -> str:
    return env.get("VPC_ID")

def get_instance_type(env: dict) -> str:
    return env.get("INSTANCE_TYPE")

def get_github_runner_token(env: dict) -> str:
    return env.get("GITHUB_RUNNER_TOKEN")

def get_github_repo_url(env: dict) -> str:
    return env.get("GITHUB_REPO_URL")

def get_runner_label(env: dict) -> str:
    return env.get("RUNNER_LABEL")

def get_number_of_runners(env: dict) -> int:
    return int(env.get("NUMBER_OF_RUNNERS"))

def get_image_central_role_arn(env: dict) -> str:
    return env.get("IMAGE_CENTRAL_ROLE_ARN")

def get_image_builder_pipeline_arn(env: dict) -> str:
    return env.get("IMAGE_BUILDER_PIPELINE_ARN")

def get_synapse_deployment_role(env: dict) -> str:
    return env.get("SYNAPSE_DEPLOYMENT_ROLE")


class SynapseGithubRunnerStack(Stack):

    def __init__(self, scope: Construct, env: dict) -> None:
        stack_prefix = f'{env.get(config.STACK_NAME_PREFIX_CONTEXT)}'
        stack_suffix = get_runner_label(env)
        stack_id = f'{stack_prefix}-{stack_suffix}'
        account_id=get_account_id(env)
        region=get_region(env)
        super().__init__(scope, stack_id, env={"account":account_id,"region":region})

        vpc_id=get_vpc_id(env)
        vpc = ec2.Vpc.from_lookup(self, vpc_id, vpc_id=vpc_id)

        # Create Security Group
        sec_group = ec2.SecurityGroup(
            self, "MySecurityGroup", vpc=vpc, allow_all_outbound=True
        )

        github_runner_token = get_github_runner_token(env)
        github_repo_url = get_github_repo_url(env)
        runner_label = get_runner_label(env)
        number_of_runners = get_number_of_runners(env)
        # make a space-separated list of runner names, e.g. "runner_1 runner_2 runner_3"
        runner_name_list = " ".join([f'{runner_label}_{i+1}' for i in range(number_of_runners)])

        # Read the content of the user-data file
        with open("resources/user_data.sh", "r") as f:
            user_data_content = f.read()
        # fill in parameters
        user_data_content = user_data_content.replace("{github_runner_token}", github_runner_token)
        user_data_content = user_data_content.replace("{github_repo_url}", github_repo_url)
        user_data_content = user_data_content.replace("{runner_label}", runner_label)
        user_data_content = user_data_content.replace("{runner_name_list}", runner_name_list)

        # user_data = ec2.UserData.for_linux()
        user_data = ec2.UserData.custom(user_data_content)

        synapse_deployment_role = get_synapse_deployment_role(env)

        if synapse_deployment_role is not None and len(synapse_deployment_role)>0:
            ec2_role = iam.Role.from_role_arn(self, "SynapseDeploymentRole", synapse_deployment_role)
        else:
            # Create an IAM role
            ec2_role = iam.Role(self, "EC2Role",
                assumed_by=iam.ServicePrincipal("ec2.amazonaws.com")  # EC2 principal
            )
            # Add managed policy (e.g., S3 read-only access)
            ec2_role.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore"))

            # Add policy to let EC2 read /synapse/admin-pat from Secrets Manager
            ec2_role.add_to_policy(iam.PolicyStatement(
                actions=["secretsmanager:GetSecretValue"],
                resources=[f"arn:aws:secretsmanager:{region}:{account_id}:secret:/synapse/admin-pat*"]
            ))

        # Get the latest AMI from the Pipeline Builder
        # This ensures the EC2 will pass CIS Level 1 security scans.
        image_central_role_arn=get_image_central_role_arn(env)
        image_builder_pipeline_arn=get_image_builder_pipeline_arn(env)
        ami = get_latest_image(image_builder_pipeline_arn, image_central_role_arn)

        instance_type = get_instance_type(env)

        # Create EC2 instance
        instance = ec2.Instance(
            self,
            "runner",
            instance_type=ec2.InstanceType(instance_type),
            machine_image=ec2.MachineImage.generic_linux({region:ami}),
            vpc=vpc,
            security_group=sec_group,
            associate_public_ip_address=False,
            user_data=user_data,
            role=ec2_role
        )

        # Output Instance ID
        CfnOutput(self, "InstanceId", value=instance.instance_id)

        # Tag all resources in this Stack's scope with context tags
        for key, value in env.get(config.TAGS_CONTEXT).items():
            Tags.of(scope).add(key, value)
