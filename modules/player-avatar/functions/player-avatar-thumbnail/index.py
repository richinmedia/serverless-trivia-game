import boto3
import uuid
from PIL import Image

s3 = boto3.client("s3")

def create_thumbnail(image_path, upload_path):
  with Image.open(image_path) as image:
    image.thumbnail((100, 100))
    image.save(upload_path, "JPEG")

def lambda_handler(event):
  try:
    id = uuid.uuid4()
    bucket = event["bucketName"]
    key = event["key"]
    download_path = '/tmp/{}{}'.format(id, key)
    upload_path = '/tmp/{}/thumb-{}'.format(id,key)
    path = key[:key.rfind("/")]
    thumbnailKey = '{}/{}'.format(path, 'thumb.jpg')

    s3.download_file(bucket, key, download_path)
    create_thumbnail(download_path, upload_path)
    s3.upload_file(upload_path, bucket, thumbnailKey)

    return {
      "statusCode": 200,
      "key": thumbnailKey,
    } 
  except Exception as e:
    print("error creating thumbnail. {}".format(e.args[-1]))
    raise