output "player_progress_topic_arn" {
  description = "Player progress topic arn"
  value       = aws_sns_topic.player_progress_topic.arn
}

output "leader_board_topic_arn" {
  description = "Leader board topic arn"
  value       = aws_sns_topic.leader_board_topic.arn
}

output "send_chat_topic_arn" {
  description = "Send chat topic arn"
  value       = aws_sns_topic.send_chat_topic.arn
}

output "player_wallet_topic_arn" {
  description = "Player wallet topic arn"
  value       = aws_sns_topic.player_wallet_topic.arn
}