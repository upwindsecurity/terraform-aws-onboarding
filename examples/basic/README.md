# Basic Example

This example demonstrates the basic usage of the main module with minimal configuration.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_main_basic"></a> [main\_basic](#module\_main\_basic) | ../../modules/main | n/a |

## Resources

| Name | Type |
|------|------|
| [random_id.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment"></a> [environment](#output\_environment) | The environment name used |
| <a name="output_name"></a> [name](#output\_name) | The name identifier used |
| <a name="output_resource_created"></a> [resource\_created](#output\_resource\_created) | Whether the example resource was created |
<!-- END_TF_DOCS -->
