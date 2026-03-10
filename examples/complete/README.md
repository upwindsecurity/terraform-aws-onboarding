# Complete Example

This example demonstrates advanced usage patterns including multiple module instances,
conditional deployments, and comprehensive configuration.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_main_complete"></a> [main\_complete](#module\_main\_complete) | ../../modules/main | n/a |
| <a name="module_main_dev"></a> [main\_dev](#module\_main\_dev) | ../../modules/main | n/a |
| <a name="module_main_optional"></a> [main\_optional](#module\_main\_optional) | ../../modules/main | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.additional_setup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_optional_resources"></a> [create\_optional\_resources](#input\_create\_optional\_resources) | Whether to create optional resources | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dev_name"></a> [dev\_name](#output\_dev\_name) | The name identifier used for dev module |
| <a name="output_dev_resource_created"></a> [dev\_resource\_created](#output\_dev\_resource\_created) | Whether the dev example resource was created |
| <a name="output_main_environment"></a> [main\_environment](#output\_main\_environment) | The environment name used for main module |
| <a name="output_main_name"></a> [main\_name](#output\_main\_name) | The name identifier used for main module |
| <a name="output_main_resource_created"></a> [main\_resource\_created](#output\_main\_resource\_created) | Whether the main example resource was created |
| <a name="output_optional_resource_created"></a> [optional\_resource\_created](#output\_optional\_resource\_created) | Whether the optional example resource was created |
<!-- END_TF_DOCS -->
