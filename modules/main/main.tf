# Example Terraform module; REPLACE with our actual resources.

resource "null_resource" "example" {
  count = var.enabled ? 1 : 0

  triggers = {
    name        = var.name
    environment = var.environment
    tags        = jsonencode(var.tags)
  }

  provisioner "local-exec" {
    command = "echo 'Hello from ${var.name} in ${var.environment}!'"
  }
}
