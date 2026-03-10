output "resource_created" {
  description = "Whether the example resource was created"
  value       = var.enabled
}

output "name" {
  description = "The name identifier used"
  value       = var.name
}

output "environment" {
  description = "The environment name used"
  value       = var.environment
}

output "tags" {
  description = "The tags applied to resources"
  value       = var.tags
}
