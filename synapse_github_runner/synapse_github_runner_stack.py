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

def get_image_central_role_arn(env: dict) -> str:
    return env.get("IMAGE_CENTRAL_ROLE_ARN")

def get_image_builder_pipeline_arn(env: dict) -> str:
    return env.get("IMAGE_BUILDER_PIPELINE_ARN")


class SynapseGithubRunnerStack(Stack):

    def __init__(self, scope: Construct, env: dict) -> None:
        stack_prefix = f'{env.get(config.STACK_NAME_PREFIX_CONTEXT)}'
        stack_id = f'{stack_prefix}-GHRunner'
        account_id=get_account_id(env)
        region=get_region(env)
        super().__init__(scope, stack_id, env={"account":account_id,"region":region})

        vpc_id=get_vpc_id(env)
        vpc = ec2.Vpc.from_lookup(self, vpc_id, vpc_id=vpc_id)

        # Create Security Group
        sec_group = ec2.SecurityGroup(
            self, "MySecurityGroup", vpc=vpc, allow_all_outbound=True
        )

        # Create Security Group Ingress Rules
        sec_group.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(22), "allow SSH access")

        github_runner_token = get_github_runner_token(env)
        github_repo_url = get_github_repo_url(env)
        runner_label = get_runner_label(env)

        user_data = ec2.UserData.for_linux()
        user_data.add_commands(
            "exec > /var/log/user-data.log 2>&1",
            "echo Running user-data script",
            "echo enabling SSM Agent",
            # https://repost.aws/knowledge-center/install-ssm-agent-ec2-linux
            "dnf update -y && sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm",
            "systemctl enable amazon-ssm-agent",
            "systemctl start amazon-ssm-agent",

            "echo Starting GitHub Self-Hosted Runner",
            "yum update && yum install libicu -y",
            "echo Adding github_runner user",
            "useradd -m github_runner",
            # Create a folder
            "su -c \"mkdir ~/actions-runner\" github_runner",
            # Here we 'cd' as root so that all the 'su'-based commands execute in the correct directory
            "cd ~github_runner/actions-runner",
            # Download the latest runner package
            "su -c \"curl -o ./actions-runner-linux-arm64-2.324.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.324.0/actions-runner-linux-arm64-2.324.0.tar.gz\" github_runner",
            # Extract the installer
            "su -c \"tar xzf ./actions-runner-linux-arm64-2.324.0.tar.gz\" github_runner",
            # Create the runner and start the configuration experience
            f"su -c \"./config.sh --unattended --replace --url {github_repo_url} --token {github_runner_token} --labels {runner_label}\" github_runner",
            # from https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service
            # Install the service with the following command:
            "./svc.sh install github_runner",
            # Start the service with the following command:
            "./svc.sh start",
            "echo User-data script completed."
        )

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
            "GitHubRunner",
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
