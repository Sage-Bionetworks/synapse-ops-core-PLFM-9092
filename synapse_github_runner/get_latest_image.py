import boto3

def get_image_builder_client(image_central_role_arn: str):
  # obtain sts token for image_central_role_arn
  sts_client = boto3.client('sts')
  assume_role_response = sts_client.assume_role(RoleArn=image_central_role_arn,RoleSessionName="image-central-session")
  temp_credentials = assume_role_response["Credentials"]
  image_central_session = boto3.Session(aws_access_key_id=temp_credentials["AccessKeyId"],
    aws_secret_access_key=temp_credentials["SecretAccessKey"],
    aws_session_token=temp_credentials["SessionToken"])

  # create image builder client, authenticated to image-central
  return image_central_session.client('imagebuilder')


def get_latest_image(image_pipeline_arn: str, image_central_role_arn: str) -> str:
  if str is None:
    return None

  image_builder_client=get_image_builder_client(image_central_role_arn)

  latest_date = None
  latest_image = None
  next_page_token = None

  while True:
    if next_page_token is None:
      list_image_pipeline_response = image_builder_client.list_image_pipeline_images(imagePipelineArn=image_pipeline_arn)
    else:
      list_image_pipeline_response = image_builder_client.list_image_pipeline_images(imagePipelineArn=image_pipeline_arn, nextToken=next_page_token)
    for image_summary in list_image_pipeline_response['imageSummaryList']:
      if 'AVAILABLE' != image_summary['state']['status']:
        continue
      amis = image_summary['outputResources']['amis']
      if len(amis)!=1:
        raise ValueError(f"Expected one AMI but found {len(amis)}")
      ami_id = amis[0]['image']
      if latest_date is None or latest_date < image_summary['dateCreated']:
        latest_image = ami_id
        latest_date = image_summary['dateCreated']
    next_page_token = list_image_pipeline_response.get('nextToken')
    if next_page_token is None:
      break
  return latest_image
