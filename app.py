#!/usr/bin/env python3
import aws_cdk as cdk
import helpers

from synapse_github_runner.synapse_github_runner_stack import SynapseGithubRunnerStack

app = cdk.App()
try:
  context, app_config = helpers.get_app_config(app)
except Exception as err:
  raise SystemExit(err)

SynapseGithubRunnerStack(app, app_config)

app.synth()
