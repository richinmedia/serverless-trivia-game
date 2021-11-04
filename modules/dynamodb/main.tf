locals {
  tags = merge(
    var.tags,
    {
      application_tier  = "database"
      os                = "dynamodb"
    }
  )
}

resource "aws_resourcegroups_group" "dynamodb" {
  name = var.resource_group_name
  tags = local.tags

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::DynamoDB::Table"
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

module "connections_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "connections"
  hash_key                      = "connectionId"
  hash_key_type                 = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  tags                          = local.tags
}

module "active_games_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "activeGames"
  hash_key                      = "gameId"
  hash_key_type                 = "S"
  range_key                     = "playerName"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 5
  autoscale_min_write_capacity  = 5
  global_secondary_index_map    = [
                                    {
                                      name                = "HostGames"
                                      hash_key            = "playerName"
                                      range_key           = "gameId"
                                      write_capacity      = 5
                                      read_capacity       = 5
                                      projection_type     = "ALL"
                                      non_key_attributes  = []
                                    }
                                  ]
  tags                          = local.tags
}

module "games_detail_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "gamesDetail"
  hash_key                      = "gameId"
  hash_key_type                 = "S"
  range_key                     = "questionNumber"
  range_key_type                = "N"
  autoscale_min_read_capacity   = 5
  autoscale_min_write_capacity  = 5
  tags                          = local.tags
}

module "high_score_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "highScore"
  hash_key                      = "gameId"
  hash_key_type                 = "S"
  range_key                     = "playerName"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 5
  autoscale_min_write_capacity  = 5
  dynamodb_attributes           = [
                                    {
                                      name                = "score"
                                      type                = "N"
                                    }
                                  ]
  global_secondary_index_map    = [
                                    {
                                      name                = "GameScore"
                                      hash_key            = "gameId"
                                      range_key           = "score"
                                      write_capacity      = 5
                                      read_capacity       = 5
                                      projection_type     = "ALL"
                                      non_key_attributes  = []
                                    }
                                  ]
  tags                          = local.tags
}

module "game_players_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "gamePlayers"
  hash_key                      = "gameId"
  hash_key_type                 = "S"
  range_key                     = "connectionId"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 5
  autoscale_min_write_capacity  = 5
  dynamodb_attributes           = [
                                    {
                                      name                = "role"
                                      type                = "S"
                                    }
                                  ]
  local_secondary_index_map     = [
                                    {
                                      name                = "GameRole"
                                      hash_key            = "gameId"
                                      range_key           = "role"
                                      projection_type     = "ALL"
                                      non_key_attributes  = []
                                    }
                                  ]
  tags                          = local.tags
}

module "player_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "player"
  hash_key                      = "playerName"
  hash_key_type                 = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  tags                          = local.tags
}

module "player_wallet_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "playerWallet"
  hash_key                      = "playerName"
  hash_key_type                 = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  tags                          = local.tags
}

module "player_progress_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "playerProgress"
  hash_key                      = "playerName"
  hash_key_type                 = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  dynamodb_attributes           = [
                                    {
                                      name                = "experience"
                                      type                = "N"
                                    }
                                  ]
  global_secondary_index_map    = [
                                    {
                                      name                = "XPIndex"
                                      hash_key            = "experience"
                                      range_key           = ""
                                      write_capacity      = 5
                                      read_capacity       = 5
                                      projection_type     = "ALL"
                                      non_key_attributes  = []
                                    }
                                  ]
  tags                          = local.tags
}

module "player_inventory_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "playerInventory"
  hash_key                      = "playerName"
  hash_key_type                 = "S"
  range_key                     = "gameId"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  tags                          = local.tags
}

module "subscription_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "subscription"
  hash_key                      = "subscription"
  hash_key_type                 = "S"
  range_key                     = "endpoint"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 5
  autoscale_min_write_capacity  = 5
  tags                          = local.tags
}

module "marketplace_table" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.29.4"

  name                          = "marketplace"
  hash_key                      = "gameId"
  hash_key_type                 = "S"
  range_key                     = "playerName"
  range_key_type                = "S"
  autoscale_min_read_capacity   = 6
  autoscale_min_write_capacity  = 6
  tags                          = local.tags
}
