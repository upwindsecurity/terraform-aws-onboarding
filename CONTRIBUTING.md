# Contributing

Thank you for your interest in contributing to this Terraform module. This document provides comprehensive
guidelines for contributors, from development setup to submitting pull requests.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code.
Please report unacceptable behavior to the project maintainers.

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker to report bugs or request features
- Before creating an issue, please search existing issues to avoid duplicates
- Provide as much detail as possible, including:
  - Terraform version
  - Provider versions
  - Steps to reproduce
  - Expected vs actual behavior

### Development Process

1. Fork the repository
2. Create a feature branch from `main` (`git checkout -b feature/amazing-feature`)
3. Make your changes following the guidelines below
4. Run tests (`make test-all`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Submit a pull request

## Development Setup

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [terraform-docs](https://terraform-docs.io/) for documentation generation
- [pre-commit](https://pre-commit.com/) for code quality checks
- [tflint](https://github.com/terraform-linters/tflint) for linting
- [trivy](https://github.com/aquasecurity/trivy) for security scanning

### Recommended Tools

- [tfenv](https://github.com/tfutils/tfenv) for Terraform version management
- [Visual Studio Code](https://code.visualstudio.com/) with Terraform extension
- [direnv](https://direnv.net/) for environment variable management

### Initial Setup

1. Clone your fork:

   ```bash
   git clone https://github.com/your-username/terraform-module-template.git
   cd terraform-module-template
   ```

2. Install pre-commit hooks:

   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

3. Run initial tests:

   ```bash
   # Install dependencies and run basic tests
   make test

   # Generate documentation for all modules
   make docs

   # Validate terraform configuration
   make test-validate

   # Format code
   make fmt
   ```

### Environment Configuration (Optional)

This project supports [direnv](https://direnv.net/) for automatic environment variable management:

1. Install direnv: `brew install direnv` (macOS) or see [direnv installation](https://direnv.net/docs/installation.html)
2. Copy the example: `cp .envrc.example .envrc`
3. Edit `.envrc` with your AWS credentials and preferences
4. Allow direnv: `direnv allow`

The `.envrc` file can contain:

- AWS profile and region settings
- Terraform variables
- Development tool configurations
- Project-specific aliases

## Development Guidelines

### Adding New Submodules

To add a new submodule to this template:

1. **Create module directory**: Create a new directory under `modules/`
2. **Add Terraform files**: Add your Terraform files (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`)
3. **Create module README**: Create a `README.md` with terraform-docs hooks (see existing modules for examples)
4. **Update main README**: Document the new submodule in the main README.md
5. **Add examples**: Create examples in the `examples/` directory
6. **Update CI/CD**: Add the new module to any CI/CD workflows

#### Module Structure

Each submodule should follow this structure:

```text
modules/
└── your-module/
    ├── main.tf          # Main resources
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    ├── versions.tf      # Provider requirements
    └── README.md        # Module documentation (terraform-docs)
```

### Coding Standards

#### Terraform Code

- Follow [Terraform best practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- Use consistent naming conventions (snake_case)
- Include descriptions for all variables and outputs
- Use appropriate variable types and validation
- Keep resources organized and well-commented
- Use meaningful variable and resource names

#### Documentation Standards

- Use terraform-docs for auto-generated documentation
- Include usage examples in module READMEs
- Document all variables with descriptions and types
- Provide meaningful output descriptions
- Include examples that demonstrate real-world usage
- Update README.md when adding new features
- Use clear, concise language
- Follow markdown best practices

#### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files

**Examples:**

```text
feat: add support for bucket lifecycle configuration
fix: resolve issue with bucket versioning
docs: update README with new examples
```

## Testing

This template includes comprehensive testing:

- **Static Analysis**: terraform validate, fmt, tflint, trivy
- **Unit Tests**: Variable validation and resource configuration
- **Integration Tests**: Complete deployment scenarios in examples/
- **Security Scanning**: Automated security vulnerability detection

### Running Tests

```bash
# Run all tests
make test-all

# Run specific test types
make test-lint
make test-security
make test-validate
make test-format

# Run tests for a specific module
make test-module MODULE=main

# Run example tests
make test-examples
```

### Test Types

#### Static Analysis

- **terraform validate**: Validates Terraform syntax and configuration
- **terraform fmt**: Checks code formatting
- **tflint**: Lints Terraform code for best practices
- **trivy**: Scans for security vulnerabilities and misconfigurations

#### Integration Tests

- **Example deployments**: Tests that examples can be deployed successfully
- **Module combinations**: Tests different module configurations
- **Provider compatibility**: Tests with different provider versions

Before submitting a pull request, ensure all tests pass:

```bash
# Run basic tests
make test

# Run all tests including security scan
make test-all

# Test examples
make test-examples
```

## Pull Request Process

### Before Submitting

1. **Update documentation** if you're adding new features
2. **Add or update tests** as appropriate
3. **Ensure all CI checks pass**
4. **Run pre-commit hooks**: `pre-commit run --all-files`

### Pull Request Template

When creating a pull request, please include:

- **Description** of changes
- **Type of change** (bug fix, new feature, etc.)
- **Testing** performed
- **Breaking changes** (if any)
- **Related issues** (if applicable)

### Review Process

1. **Request review** from maintainers
2. **Address feedback** promptly
3. **Keep pull requests focused** and atomic
4. **Be responsive** to reviewer comments

## Code Review Guidelines

### For Contributors

- Keep pull requests focused and atomic
- Write clear commit messages
- Include tests for new functionality
- Update documentation as needed
- Be responsive to feedback

### For Reviewers

- Be constructive and helpful
- Focus on code quality and maintainability
- Check for security implications
- Verify tests are adequate
- Ensure documentation is updated

## Release Process

This project uses automated releases with semantic versioning, powered by [semantic-release](https://semantic-release.gitbook.io/semantic-release/):

1. **Conventional Commits**: Ensure all commits follow the [Conventional Commits](https://www.conventionalcommits.org/) format.
2. **Pull Request to `main`**: Open a pull request with your changes targeting the `main` branch.
3. **Merge the Pull Request**: Once your pull request is approved and merged, the release workflow will automatically run.
4. **Automated Release**: If your commits warrant a new release (according to semantic versioning rules), a new release
   will be created, a tag will be pushed, and release notes will be generated.
5. **Release Branch and Pull Request**: After a successful release, the workflow will automatically create a release
   branch (e.g., `release-x.y.z`) and open a pull request with the release changes (such as updated changelog and
   version bump). Review and merge this pull request to keep your main branch up to date with release artifacts.

**Note:**

- Releases are only triggered when a pull request is merged to `main`.
- No release will be published for pull requests that are closed without merging.
- After a release, a new release branch and pull request will be created automatically for release-related
  changes.

For more details, see `.github/workflows/release.yml`.

### Workflow Files

- `.github/workflows/ci.yml` - Continuous integration
- `.github/workflows/release.yml` - Release automation
- `.github/workflows/docs.yml` - Documentation updates

### Continuous Integration

The project includes GitHub Actions workflows for:

- **Pull Request Validation**: Runs tests on pull requests
- **Release Management**: Automates semantic versioning and releases
- **Documentation**: Updates module documentation
- **Security Scanning**: Regular security vulnerability checks

## Troubleshooting

### Common Issues

**terraform-docs not updating**:

```bash
# Manually run terraform-docs
terraform-docs markdown table --output-file README.md modules/main/
```

**Pre-commit hooks failing**:

```bash
# Run pre-commit manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

**Tests failing locally**:

```bash
# Clean up test artifacts
make clean

# Run tests step by step
make test-validate
make test-format
make test-lint
make test-security
```

## Useful Commands

```bash
# Format code
make fmt

# Validate configuration
make test-validate

# Run linting
make test-lint

# Generate documentation
make docs

# Run security scan
make test-security

# Clean up
make clean

# Initialize Terraform
make init

# Setup development environment
make setup

# Install required tools
make install-tools

# Run pre-commit hooks
make pre-commit

# Run all tests
make test-all
```

## Getting Help

If you have questions or need help:

- Check [existing issues](https://github.com/upwindsecurity/terraform-module/issues)
- Start a [Discussion](https://github.com/upwindsecurity/terraform-module/discussions)
- Review the [main README](README.md)

## Questions?

If you have questions about contributing, please:

1. Check this guide and the [README](README.md)
2. Search [existing issues](https://github.com/upwindsecurity/terraform-module/issues)
3. Create a new issue with the `question` label

Thank you for contributing! 🎉
