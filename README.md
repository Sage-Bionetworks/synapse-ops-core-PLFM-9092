# synapse-ops-core
Synapse Ops scripts, workflows, and CDK + workflow for creating self-hosted runners

Runner can see `/synapse/admin-pat` in Secrets Manager.


The scripts for the ops' jobs are in the `scripts/` folder.
Each is called from a workflow invoked via `on: workflow_call` from another repository.
The calling repository will provide an AWS role its authorized to use. The runner will be set up in the caller's repository,
so that it's not available to any other.  (This avoids the possibility of confusing 'dev' and 'prod' operations.)


To build a self-hosted runner using the AWS-CDK CLI:

```
cdk deploy --all --context env=dev \
--context github_runner_token=AAMNJ...IGNBOK \
--context github_repo_url=... \
--context runner_label=... \
--context instance_type=...

```
`github_runner_token` is the token to attach a runner to a repo', obtained by visiting the repo' and selecting
Settings > Actions > Runners > New Self-Hosted Runner, then scroll down to "Configure" and copy the token;

`github_repo_url` is the URL to the repo' which will use the runner,
`https://github.com/Sage-Bionetworks/synapse-ops-dev` or `https://github.com/Sage-Bionetworks/synapse-ops-prod`;

`runner_label` is the label for the self-hosted runner, e.g., `shared-runner`;

`instance_type` is the EC2 instance type for the self-hosted runner, e.g. `t4g.small`
