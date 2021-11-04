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
  "TagFilters": [
    "Key": "product",
    "Values": [${var.product}]
  ]
}
JSON
  }
}

####### DynamoDB Tables #######

module "dynamodb" {
  source = "../modules/dynamodb"

  product             = var.product
  resource_group_name = "dynamo-db"
  tags                = local.tags
}