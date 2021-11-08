variable "product" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the ResourceGroup for resources in this template"
  type        = string
  default     = "player-avatar"
}

variable "log_retention_days" {
  description = "Days to retain CloudWatch Logs for the Lambda Functions"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to applied to resources"
  type        = map
  default     = {}
}