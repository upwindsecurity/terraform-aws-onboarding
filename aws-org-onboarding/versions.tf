terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0" # Or the latest version
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13" # Or the latest version
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0" # Or the latest version
    }

  }
}

