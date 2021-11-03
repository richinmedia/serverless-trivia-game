variable "product" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the ResourceGroup for resources in this template"
  type        = string
  default     = "dynamo-db"
}

variable "tags" {
  description = "Tags to applied to resources"
  type        = map
  default     = {}
}