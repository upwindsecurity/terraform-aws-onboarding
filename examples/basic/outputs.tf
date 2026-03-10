output "resource_created" {
  description = "Whether the example resource was created"
  value       = module.main_basic.resource_created
}

output "name" {
  description = "The name identifier used"
  value       = module.main_basic.name
}

output "environment" {
  description = "The environment name used"
  value       = module.main_basic.environment
}
