from unittest import TestCase
from unittest.mock import patch
from synapse_github_runner.get_latest_image import get_latest_image
import boto3

class SimpleMockImageBuilderClient():
  mock_image_pipeline_response = {
    "imageSummaryList":[
      {"dateCreated":"2025-04-05T23:39:43.900Z",
       "state":{"status": "AVAILABLE"},
       "outputResources":{"amis":[{"image":"ami-12345"}]}
     }]}

  def list_image_pipeline_images(self, imagePipelineArn, **kwargs):
    next_token = kwargs.get('nextToken')
    return self.mock_image_pipeline_response


class ComplexMockImageBuilderClient():
  # two pages:
  # first page has an available image
  # first page has a broken image with a later date
  # second page has an available image with an earlier date

  mock_image_pipeline_page_1 = {
    "imageSummaryList":[
      {"dateCreated":"2025-04-05T23:39:43.900Z",
       "state":{"status": "AVAILABLE"},
       "outputResources":{"amis":[{"image":"ami-12345"}]}
     },
      {"dateCreated":"2025-04-06T23:39:43.900Z",
       "state":{"status": "CANCELLED"},
       "outputResources":{"amis":[{"image":"ami-cancelled"}]}
     }
     ], "nextToken":"some-token"}


  mock_image_pipeline_page_2 = {
    "imageSummaryList":[
      {"dateCreated":"2025-04-01T23:39:43.900Z",
       "state":{"status": "AVAILABLE"},
       "outputResources":{"amis":[{"image":"ami-old-image"}]}
     }]}

  def list_image_pipeline_images(self, imagePipelineArn, **kwargs):
    next_token = kwargs.get('nextToken')
    if next_token is None:
      return self.mock_image_pipeline_page_1
    else:
      return self.mock_image_pipeline_page_2


class TestGetLatestImage(TestCase):

  @patch("synapse_github_runner.get_latest_image.get_image_builder_client")
  def test_get_latest_image_simple(self, mock_get_image_builder_client):
      mock_get_image_builder_client.return_value=SimpleMockImageBuilderClient()

      # method under test
      result = get_latest_image("pipeline-arn","role-arn")

      expected_ami = "ami-12345"
      self.assertEqual(result, expected_ami)

  @patch("synapse_github_runner.get_latest_image.get_image_builder_client")
  def test_get_latest_image_complex(self, mock_get_image_builder_client):
      mock_get_image_builder_client.return_value=ComplexMockImageBuilderClient()

      # method under test
      result = get_latest_image("pipeline-arn","role-arn")

      expected_ami = "ami-12345"
      self.assertEqual(result, expected_ami)
