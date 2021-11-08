locals {
  service       = "player-avatar-service"
  s3_origin_id  = "S3PlayerAvatarOrigin"
  
  tags          = merge(
                    var.tags,
                    {
                      service = local.service
                    }
                  )
}

data "aws_caller_identity" "current" {}

resource "aws_resourcegroups_group" "player_avatar" {
  name = var.resource_group_name
  tags = local.tags

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "service",
      "Values": ["${local.service}"]
    }
  ]
}
JSON
  }
}

// PlayerAvatarBucket
resource "aws_s3_bucket" "bucket" {
  bucket  = "${local.service}-bucket"
  acl     = "private"

  cors_rule {
    allowed_headers = [ "*" ]
    allowed_methods = [ "GET", "PUT", "HEAD" ]
    allowed_origins = [ "*" ]
  }

  tags = merge(
    local.tags,
    {
      application_type = "S3"
      application_name = "player-avatar-bucket"
    }
  )
}

data "aws_iam_policy_document" "bucket" {
  version = "2008-10-17"

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    principals {
      type = "CanonicalUser"
      identifiers = [
        "${aws_cloudfront_origin_access_identity.cloudfront_oai.s3_canonical_user_id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket.json
}

// PlayerAvatarLoggingBucket
resource "aws_s3_bucket" "log_bucket" {
  bucket  = "${local.service}-log-bucket"
  acl     = "private"

  tags  = merge(
    local.tags,
    {
      application_type = "S3"
      application_name = "player-avatar-log-bucket"
    }
  )
}

// PlayerAvatarLoggingBucketPolicy
data "aws_iam_policy_document" "log_bucket" {
  version         = "2012-10-17"

  statement {
    sid           = "AWSCloudTrailAclCheck"
    effect        = "Allow"
    
    actions       = [ "s3:GetBucketAcl" ]
    resources     = [
                      "${aws_s3_bucket.log_bucket.arn}"
                    ]

    principals {
      type        = "Service"
      identifiers = [ "cloudtrail.amazonaws.com" ]
    }
  }

  statement {
    sid           = "AWSCloudTrailWrite"
    effect        = "Allow"
    
    actions       = [ "s3:PutObject" ]
    resources     = [
                      "${aws_s3_bucket.log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
                    ]
    
    principals {
      type        = "Service"
      identifiers = [ "cloudtrail.amazonaws.com" ]
    }

    condition {
      test        = "StringEquals"
      variable    = "s3:x-amz-acl"
      values      = [ "bucket-owner-full-control" ] 
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.log_bucket.json
}

// PlayerAvatarDistribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.service}: CloudFront Distribution for player avatars"

  origin {
    domain_name         = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id           = local.s3_origin_id
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods         = [ "GET", "PUT", "HEAD" ]
    cached_methods          = [ "GET", "HEAD" ]
    target_origin_id        = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy  = "https-only"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type  = "whitelist"
      locations         = [ "GB" ]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    local.tags,
    {
      application_type = "Cloudfront"
    }
  )
}

resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "Origin Access Identity for ${local.service}"
}

// PlayerAvatarLogGroup
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/${var.product}/statemachines/${local.service}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.tags,
    {
      application_type = "Cloudwatch"
    }
  )
}

// PlayerAvatarTrail
// Requires
// - PlayerAvatarBucketPolicy
// - PlayerAvatarLoggingBucket

// PlayerAvatarModerateFunction
// Requires
// - Player Avatar S3 bucket
// - Cloudwatch Lambda insight exec role policy

// PlayerAvatarStateMachine
// Requires
// - PlayerAvatarModerateFunction
// - PlayerAvatarThumbnailFunction
// - PlayerAvatarDeleteFunction
// - PlayerAvatarDistribution
// - PlayerAvatarBucket.DomainName
// - STSEventBus
// - PlayerAvatarLogGroup