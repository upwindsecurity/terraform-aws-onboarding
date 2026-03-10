variable "enabled" {
  description = "Whether to create the resources in this module"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name identifier for resources"
  type        = string
  default     = "example"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
