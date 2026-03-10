# Outputs from the main complete module
output "main_resource_created" {
  description = "Whether the main example resource was created"
  value       = module.main_complete.resource_created
}

output "main_name" {
  description = "The name identifier used for main module"
  value       = module.main_complete.name
}

output "main_environment" {
  description = "The environment name used for main module"
  value       = module.main_complete.environment
}

# Outputs from the optional module
output "optional_resource_created" {
  description = "Whether the optional example resource was created"
  value       = module.main_optional.resource_created
}

# Outputs from the dev module
output "dev_resource_created" {
  description = "Whether the dev example resource was created"
  value       = module.main_dev.resource_created
}

output "dev_name" {
  description = "The name identifier used for dev module"
  value       = module.main_dev.name
}
