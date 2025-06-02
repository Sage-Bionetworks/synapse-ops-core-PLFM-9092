import aws_cdk
import config

def get_app_config(app: aws_cdk.App) -> dict:
  context = app.node.try_get_context('env')
  if context is None or context not in config.CONTEXT_ENVS:
    raise ValueError(
      "ERROR: CDK env context not provide or is invalid. "
      "Try passing in one of the available contexts: "
      + ', '.join(config.CONTEXT_ENVS))

  app_config = app.node.try_get_context(context)

  # get additional values passed in as synth parameters
  # for convenience we add them to the app_config map
  app_config["GITHUB_RUNNER_TOKEN"]=app.node.try_get_context("github_runner_token")
  app_config["GITHUB_REPO_URL"]=app.node.try_get_context("github_repo_url")
  app_config["RUNNER_LABEL"]=app.node.try_get_context("runner_label")
  app_config["INSTANCE_TYPE"]=app.node.try_get_context("instance_type")
  app_config["SYNAPSE_DEPLOYMENT_ROLE"]=app.node.try_get_context("synapse_deployment_role")

  return context, app_config
