# Upwind AWS Onboarding Terraform Module

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)](https://opensource.org/licenses/Apache-2.0)

Terraform modules for onboarding the accounts of an AWS Organization into
[Upwind](https://www.upwind.io/). The modules create the IAM roles, policies
and supporting resources that allow Upwind to discover, audit and scan the
accounts in your organization.

## Modules

This repository contains the following Terraform modules:

- [modules/main/aws-org-onboarding/](https://github.com/upwindsecurity/terraform-aws-onboarding/tree/main/modules/main/aws-org-onboarding) -
  Creates the IAM roles, policies and resources required to onboard the
  accounts of an AWS Organization into Upwind. The module is designed to be
  applied to each account in the organization (for example via Terragrunt or a
  similar IaC tool), creating the appropriate resources based on the account
  type (management, orchestrator or other). See the
  [module README](https://github.com/upwindsecurity/terraform-aws-onboarding/blob/main/modules/main/aws-org-onboarding/README.md)
  for a full description of the onboarding process, the roles created, and the
  available inputs and outputs.

## Examples

Complete usage examples are available in the [examples](https://github.com/upwindsecurity/terraform-aws-onboarding/tree/main/examples) directory:

- [examples/aws-org-onboarding/](https://github.com/upwindsecurity/terraform-aws-onboarding/tree/main/examples/aws-org-onboarding) -
  Example usage of the AWS Organization onboarding module

## Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](https://github.com/upwindsecurity/terraform-aws-onboarding/blob/main/CONTRIBUTING.md) guide for details on:

- Development setup and workflows
- Testing procedures
- Code standards and best practices
- How to add new submodules

For bug reports and feature requests, please use
[GitHub Issues](https://github.com/upwindsecurity/terraform-aws-onboarding/issues).

## Versioning ##

We use [Semantic Versioning](http://semver.org/) for releases. For the versions
available, see the [releases on this repository](https://github.com/upwindsecurity/terraform-aws-onboarding/releases).

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](https://github.com/upwindsecurity/terraform-aws-onboarding/blob/main/LICENSE) file for details.

## Support ##

- [Documentation](https://docs.upwind.io)
- [Issues](https://github.com/upwindsecurity/terraform-aws-onboarding/issues)
- [Contributing Guide](https://github.com/upwindsecurity/terraform-aws-onboarding/blob/main/CONTRIBUTING.md)
