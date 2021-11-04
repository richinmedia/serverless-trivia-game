output "connections_table" {
  description = "DynamoDB table name, id and arn for connections table"
  value = {
    table_name  = module.connections_table.table_name
    table_id    = module.connections_table.table_name
    table_arn   = module.connections_table.table_name
  }
}

output "active_games_table" {
  description = "DynamoDB table name, id and arn for activeGames table"
  value = {
    table_name  = module.active_games_table.table_name
    table_id    = module.active_games_table.table_name
    table_arn   = module.active_games_table.table_name
  }
}

output "games_detail_table" {
  description = "DynamoDB table name, id and arn for gamesDetail table"
  value = {
    table_name  = module.games_detail_table.table_name
    table_id    = module.games_detail_table.table_name
    table_arn   = module.games_detail_table.table_name
  }
}

output "high_score_table" {
  description = "DynamoDB table name, id and arn for highScore table"
  value = {
    table_name  = module.high_score_table.table_name
    table_id    = module.high_score_table.table_name
    table_arn   = module.high_score_table.table_name
  }
}

output "game_players_table" {
  description = "DynamoDB table name, id and arn for gamePlayers table"
  value = {
    table_name  = module.game_players_table.table_name
    table_id    = module.game_players_table.table_name
    table_arn   = module.game_players_table.table_name
  }
}

output "player_table" {
  description = "DynamoDB table name, id and arn for player table"
  value = {
    table_name  = module.player_table.table_name
    table_id    = module.player_table.table_name
    table_arn   = module.player_table.table_name
  }
}

output "player_wallet_table" {
  description = "DynamoDB table name, id and arn for playerWallet table"
  value = {
    table_name  = module.player_wallet_table.table_name
    table_id    = module.player_wallet_table.table_name
    table_arn   = module.player_wallet_table.table_name
  }
}

output "player_progress_table" {
  description = "DynamoDB table name, id and arn for playerProgress table"
  value = {
    table_name  = module.player_progress_table.table_name
    table_id    = module.player_progress_table.table_name
    table_arn   = module.player_progress_table.table_name
  }
}

output "player_inventory_table" {
  description = "DynamoDB table name, id and arn for playerInventory table"
  value = {
    table_name  = module.player_inventory_table.table_name
    table_id    = module.player_inventory_table.table_name
    table_arn   = module.player_inventory_table.table_name
  }
}

output "subscription_table" {
  description = "DynamoDB table name, id and arn for subscription table"
  value = {
    table_name  = module.subscription_table.table_name
    table_id    = module.subscription_table.table_name
    table_arn   = module.subscription_table.table_name
  }
}

output "marketplace_table" {
  description = "DynamoDB table name, id and arn for marketplace table"
  value = {
    table_name  = module.marketplace_table.table_name
    table_id    = module.marketplace_table.table_name
    table_arn   = module.marketplace_table.table_name
  }
}