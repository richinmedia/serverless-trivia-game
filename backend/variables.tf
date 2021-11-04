variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "product" {
  type = string
  default = "Serverless Trivia Game"
}

variable "terraform_version" {
  type = string
  default = "1.0.10"
}

variable "log_retention_days" {
  description = "Days to retain CloudWatch Logs for the Lambda Functions"
  type        = number
  default     = 30
}

variable "resource_group_prefix" {
  description = "Name of the Resource Group prefix"
  type        = string
  default     = "game-service"
}

variable "emf_namespace" {
  description = "Name of the EMF Namespace"
  type        = string
  default     = "STS"
}

variable "s3_buffer_interval" {
  description = "Number of seconds to buffer data before delivering to S3 (60 to 900)."
  type        = number
  default     = 60

  validation {
    condition     = var.s3_buffer_interval >= 60 && var.s3_buffer_interval <= 900
    error_message = "The buffer interval must be between 60 and 900."
  }
}

variable "s3_buffer_size" {
  description = "Number of MB of data to buffer before delivering to S3 (1 to 128)."
  type        = number
  default     = 5

  validation {
    condition     = var.s3_buffer_size >= 1 && var.s3_buffer_size <= 128
    error_message = "The buffer interval must be between 1 and 128."
  }
}

variable "kinesis_shard_count" {
  description = "Kinesis shard count"
  type        = number
  default     = 1
}