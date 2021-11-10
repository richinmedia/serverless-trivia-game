locals {
  service       = "player-avatar-service"
  s3_origin_id  = "S3PlayerAvatarOrigin"
  
  tags          = merge(
                    var.tags,
                    {
                      service             = local.service
                      application_name    = "player-avatar"
                    }
                  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


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

##########################
# Player Avatar S3 Bucket
##########################

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

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${local.service}-log-bucket"
  acl           = "private"
  force_destroy = true

  tags  = merge(
    local.tags,
    {
      application_type = "S3"
      application_name = "player-avatar-log-bucket"
    }
  )
}

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

########################################
# Player Avatar Cloudfront Distribution
########################################

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
      application_type = "cloudfront"
    }
  )
}

resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "Origin Access Identity for ${local.service}"
}

###########################
# Player Avatar Cloudtrail
###########################

resource "aws_cloudtrail" "trail" {
  name                          = "${aws_s3_bucket.bucket.bucket}-Trail"
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  include_global_service_events = false
  enable_logging                = true
  is_multi_region_trail         = false

  event_selector {
    read_write_type = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"

      values = [ "${aws_s3_bucket.bucket.arn}/" ]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.bucket_policy
  ]
}

#################################
# Player Avatar Lambda Functions
#################################

module "player_avatar_moderate_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "player-avatar-moderate"
  description   = "Detects inappropriate content in an image."
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  memory_size   = 1024
  timeout       = 10

  cloudwatch_logs_retention_in_days = var.log_retention_days

  tracing_mode          = "Active"
  attach_tracing_policy = true

  source_path   = "${path.module}/functions/player-avatar-moderate"
  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [ "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:14" ]

  role_name = "player-avatar-moderate-role"
  
  attach_policies     = true
  policies            = [
                          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
                          "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
                        ]
  number_of_policies  = 2

  attach_policy_statements = true
  policy_statements = {
    s3_read = {
      effect    = "Allow",
      actions   = [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:GetObjectVersion",
                    "s3:GetLifecycleConfiguration"
                  ],
      resources = [
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
                  ]
    },
    s3_write = {
      effect    = "Allow",
      actions   = [
                    "s3:PutObject",
                    "s3:PutObjectAcl",
                    "s3:PutLifecycleConfiguration"
                  ],
      resources = [
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
                  ]
    },
    rekognition_detect_moderation_labels = {
      effect    = "Allow",
      actions   = [ "rekognition:DetectModerationLabels" ],
      resources = [ "*" ]
    }
  }

  environment_variables = {
    PLAYER_AVATAR_BUCKET = aws_s3_bucket.bucket.arn
  }

  tags = merge(
    local.tags,
    {
      application_type    = "lambda"
      os                  = "python"
      application_version = "3.8"
      application_name    = "player-avatar-moderate"
    }
  )
}

module "player_avatar_moderate_function_alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"
  
  refresh_alias     = false
  name              = "HTTPLive"

  function_name     = module.player_avatar_moderate_function.lambda_function_name
  function_version  = module.player_avatar_moderate_function.lambda_function_version
}

module "player_avatar_thumbnail_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "player-avatar-thumbnail"
  description   = "Creates a thumbnail from users avatar image."
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  memory_size   = 1024
  timeout       = 10

  cloudwatch_logs_retention_in_days = var.log_retention_days

  tracing_mode          = "Active"
  attach_tracing_policy = true

  source_path   = "${path.module}/functions/player-avatar-thumbnail"
  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [ "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:14" ]

  role_name = "player-avatar-thumbnail-role"
  
  attach_policies     = true
  policies            = [
                          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
                          "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
                        ]
  number_of_policies  = 2

  attach_policy_statements = true
  policy_statements = {
    s3_crud = {
      effect    = "Allow",
      actions   = [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:GetObjectVersion",
                    "s3:PutObject",
                    "s3:PutObjectAcl",
                    "s3:GetLifecycleConfiguration",
                    "s3:PutLifecycleConfiguration",
                    "s3:DeleteObject"
                  ],
      resources = [
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
                  ]
    }
  }

  tags = merge(
    local.tags,
    {
      application_type    = "lambda"
      os                  = "python"
      application_version = "3.8"
      application_name    = "player-avatar-thumbnail"
    }
  )
}

module "player_avatar_thumbnail_function_alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"
  
  refresh_alias     = false
  name              = "HTTPLive"

  function_name     = module.player_avatar_thumbnail_function.lambda_function_name
  function_version  = module.player_avatar_thumbnail_function.lambda_function_version
}

module "player_avatar_delete_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "player-avatar-delete"
  description   = "Delete users avatar image."
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  memory_size   = 1024
  timeout       = 10

  cloudwatch_logs_retention_in_days = var.log_retention_days

  tracing_mode          = "Active"
  attach_tracing_policy = true

  source_path   = "${path.module}/functions/player-avatar-delete"
  artifacts_dir = "${path.root}/.terraform/lambda-builds/"

  layers = [ "arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension:14" ]

  role_name = "player-avatar-delete-role"
  
  attach_policies     = true
  policies            = [
                          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
                          "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
                        ]
  number_of_policies  = 2

  attach_policy_statements = true
  policy_statements = {
    s3_crud = {
      effect    = "Allow",
      actions   = [
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:GetObjectVersion",
                    "s3:PutObject",
                    "s3:PutObjectAcl",
                    "s3:GetLifecycleConfiguration",
                    "s3:PutLifecycleConfiguration",
                    "s3:DeleteObject"
                  ],
      resources = [
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
                    "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
                  ]
    }
  }

  tags = merge(
    local.tags,
    {
      application_type    = "lambda"
      os                  = "python"
      application_version = "3.8"
      application_name    = "player-avatar-delete"
    }
  )
}

module "player_avatar_delete_function_alias" {
  source = "terraform-aws-modules/lambda/aws//modules/alias"
  
  refresh_alias     = false
  name              = "HTTPLive"

  function_name     = module.player_avatar_delete_function.lambda_function_name
  function_version  = module.player_avatar_delete_function.lambda_function_version
}

##############################
# Player Avatar State Machine
##############################

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/${var.product}/statemachines/${local.service}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.tags,
    {
      application_type = "cloudwatch"
    }
  )
}

// PlayerAvatarStateMachine
// Requires
// - PlayerAvatarModerateFunction
// - PlayerAvatarThumbnailFunction
// - PlayerAvatarDeleteFunction
// - PlayerAvatarDistribution
// - PlayerAvatarBucket.DomainName
// - STSEventBus
// - PlayerAvatarLogGroup