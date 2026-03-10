module "main_basic" {
  source = "../../modules/main"

  enabled     = true
  name        = "basic-example"
  environment = "dev"

  tags = {
    Environment = "dev"
    Project     = "terraform-module-template"
    Example     = "basic"
  }
}
