terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0" # Or the latest version
    }
  }
}

