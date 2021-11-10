import boto3

s3 = boto3.client("s3")

def lambda_handler(event):
  try:
      return s3.delete_object(Bucket=event["bucketName"], Key=event["key"])
  except Exception as e:
    print("error deleting avatar. {}".format(e.args[-1]))
    raise