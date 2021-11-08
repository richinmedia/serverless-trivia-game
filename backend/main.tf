locals {
  tags = {
    product   = var.product
    region    = var.region
    service   = var.resource_group_prefix
    terraform = "Provisioned by Terraform ${var.terraform_version}"
  }
}
resource "aws_resourcegroups_group" "main" {
  name = "${var.resource_group_prefix}-Main"
  tags = local.tags

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "product",
      "Values": ["${var.product}"]
    }
  ]
}
JSON
  }
}

resource "aws_cloudwatch_event_bus" "name" {
  name = var.service_abbr
}

####### DynamoDB Tables #######

module "dynamodb" {
  source = "../modules/dynamodb"

  product             = var.product
  resource_group_name = "${var.resource_group_prefix}-DynamoDB"
  tags                = local.tags
}

######### SNS Topics #########

module "sns" {
  source = "../modules/sns"
  
  tags                = local.tags
}

######### Player Avatar Service #########
module "name" {
  source = "../modules/player-avatar"

  product             = var.product
  resource_group_name = "${var.resource_group_prefix}-PlayerAvatar"
  log_retention_days  = var.log_retention_days
  tags                = local.tags
}