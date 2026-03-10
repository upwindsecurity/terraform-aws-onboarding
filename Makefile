.PHONY: help init fmt docs pre-commit test-validate test-format test-lint test-security test test-all test-module test-examples clean install-tools setup

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize all Terraform modules and examples
	@echo "Initializing all Terraform modules..."
	@for module in modules/*/; do \
		if [ -f "$$module/versions.tf" ] || [ -f "$$module/main.tf" ]; then \
			echo "Initializing $$module"; \
			cd $$module && terraform init -upgrade && cd ../..; \
		fi; \
	done
	@echo "Initializing all Terraform examples..."
	@for example in examples/*/; do \
		if [ -f "$$example/versions.tf" ] || [ -f "$$example/main.tf" ]; then \
			echo "Initializing $$example"; \
			cd $$example && terraform init -upgrade && cd ../..; \
		fi; \
	done

fmt: ## Format Terraform code
	terraform fmt -recursive modules/
	terraform fmt -recursive examples/

docs: ## Generate documentation
	@echo "Generating documentation using terraform-docs..."
	@$(MAKE) pre-commit HOOK=terraform_docs

pre-commit: ## Run pre-commit hooks on all files
	pre-commit run $(if $(HOOK),$(HOOK),) --all-files --config .config/.pre-commit-config.yml

test-validate: ## Run validation tests on all modules and examples
	@echo "Validating all Terraform modules..."
	@for module in modules/*/; do \
		if [ -f "$$module/versions.tf" ] || [ -f "$$module/main.tf" ]; then \
			echo "Validating $$module"; \
			cd $$module && terraform validate && cd ../..; \
		fi; \
	done
	@echo "Validating all Terraform examples..."
	@for example in examples/*/; do \
		if [ -f "$$example/versions.tf" ] || [ -f "$$example/main.tf" ]; then \
			echo "Validating $$example"; \
			cd $$example && terraform validate && cd ../..; \
		fi; \
	done

test-format: ## Run format tests
	terraform fmt -check -recursive modules/
	terraform fmt -check -recursive examples/

test-lint: ## Run linting tests
	tflint --init || echo "Warning: TFLint plugin initialization failed, continuing with basic linting"
	tflint --config .config/.tflint.hcl

test-security: ## Run security tests
	trivy config .

test: test-validate test-format test-lint ## Run basic tests

test-all: test test-security ## Run all tests including security scan

test-module: ## Run tests for a specific module or example (use MODULE=module_name or EXAMPLE=example_name)
	@if [ -n "$(MODULE)" ]; then \
		if [ ! -d "modules/$(MODULE)" ]; then \
			echo "Error: Module 'modules/$(MODULE)' does not exist"; \
			echo "Available modules:"; \
			ls -1 modules/ | sed 's/^/  - /'; \
			exit 1; \
		fi; \
		echo "Testing module: $(MODULE)"; \
		cd modules/$(MODULE) && terraform init && terraform validate && cd ../..; \
		terraform fmt -check modules/$(MODULE)/; \
		tflint --config .config/.tflint.hcl modules/$(MODULE)/; \
		trivy config modules/$(MODULE)/ --exit-code 0; \
	elif [ -n "$(EXAMPLE)" ]; then \
		if [ ! -d "examples/$(EXAMPLE)" ]; then \
			echo "Error: Example 'examples/$(EXAMPLE)' does not exist"; \
			echo "Available examples:"; \
			ls -1 examples/ | sed 's/^/  - /'; \
			exit 1; \
		fi; \
		echo "Testing example: $(EXAMPLE)"; \
		cd examples/$(EXAMPLE) && terraform init && terraform validate && cd ../..; \
		terraform fmt -check examples/$(EXAMPLE)/; \
		tflint --config .config/.tflint.hcl examples/$(EXAMPLE)/; \
		trivy config examples/$(EXAMPLE)/ --exit-code 0; \
	else \
		echo "Error: MODULE or EXAMPLE parameter is required."; \
		echo "Usage: make test-module MODULE=project"; \
		echo "   or: make test-module EXAMPLE=organization"; \
		echo ""; \
		echo "Available modules:"; \
		ls -1 modules/ | sed 's/^/  - /'; \
		echo ""; \
		echo "Available examples:"; \
		ls -1 examples/ | sed 's/^/  - /'; \
		exit 1; \
	fi

test-examples: ## Test all examples
	@echo "Testing all examples..."
	@for example in examples/*/; do \
		if [ -f "$$example/versions.tf" ] || [ -f "$$example/main.tf" ]; then \
			echo "Testing $$example"; \
			cd $$example && terraform init && terraform validate && cd ../..; \
		fi; \
	done

clean: ## Clean up temporary files
	find . -type f -name "*.tfplan" -delete
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name ".terraform.lock.hcl" -delete

install-tools: ## Install required tools
	@echo "Installing required tools..."
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew is required but not installed. Please install Homebrew first."; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "Installing Terraform..."; brew install terraform; }
	@command -v tflint >/dev/null 2>&1 || { echo "Installing TFLint..."; brew install tflint; }
	@command -v trivy >/dev/null 2>&1 || { echo "Installing Trivy..."; brew install trivy; }
	@command -v terraform-docs >/dev/null 2>&1 || { echo "Installing terraform-docs..."; brew install terraform-docs; }
	@command -v pre-commit >/dev/null 2>&1 || { echo "Installing pre-commit..."; brew install pre-commit; }
	@command -v direnv >/dev/null 2>&1 || { echo "Installing direnv..."; brew install direnv; }
	@echo "All tools are installed!"

setup: install-tools ## Setup development environment
	pre-commit install --config .config/.pre-commit-config.yml
	pre-commit install --hook-type commit-msg --config .config/.pre-commit-config.yml
	@echo "Development environment setup complete!"
