import boto3

rekognition = boto3.client("rekognition")

def detect_inappropriate_content(bucket, key, minConfidence=75):
  try:
    response = rekognition.detect_moderation_labels(
      Image={
        "S3Object": {
          "Bucket": bucket,
          "Name": key,
        }
      },
      MinConfidence=minConfidence
    )
    return {
      "statusCode": 200,
      "appropriate": (response.ModerationLabels.length == 0),
      "moderationLabels": response.ModerationLabels,
    }
  except Exception as e:
    print("error in moderation step. {}".format(e.args[-1]))
    raise
    

def lambda_handler(event):
  return detect_inappropriate_content(event["bucketName"], event["key"])
    