locals {
  tags = merge(
    var.tags,
    {
      application_tier  = "sns"
    }
  )
}

resource "aws_sns_topic" "player_progress_topic" {
  name = "player-progress-topic"
  tags = local.tags
}

resource "aws_sns_topic" "leader_board_topic" {
  name = "leader-board-topic"
  tags = local.tags
}

resource "aws_sns_topic" "send_chat_topic" {
  name = "send-chat-topic"
  tags = local.tags
}

resource "aws_sns_topic" "player_wallet_topic" {
  name = "player-wallet-topic"
  tags = local.tags
}
