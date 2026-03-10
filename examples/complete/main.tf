module "main_complete" {
  source = "../../modules/main"

  enabled     = true
  name        = "complete-example"
  environment = "production"

  tags = {
    Environment = "production"
    Project     = "terraform-module-template"
    Example     = "complete"
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    ManagedBy   = "Terraform"
  }
}

# Example of conditional module usage
module "main_optional" {
  source = "../../modules/main"

  enabled     = var.create_optional_resources
  name        = "optional-example"
  environment = "staging"

  tags = {
    Environment = "staging"
    Project     = "terraform-module-template"
    Example     = "complete"
    Purpose     = "conditional-deployment"
  }
}

# Example showing different environments
module "main_dev" {
  source = "../../modules/main"

  enabled     = true
  name        = "dev-example"
  environment = "development"

  tags = {
    Environment = "development"
    Project     = "terraform-module-template"
    Example     = "complete"
    Temporary   = "true"
  }
}

# Example of additional resources that might be created alongside the main module
resource "null_resource" "additional_setup" {
  count = var.create_optional_resources ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Additional setup completed for complete example'"
  }

  depends_on = [module.main_complete]
}
