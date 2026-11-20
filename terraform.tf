terraform {
  required_version = ">= 1.9.0"

  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.18"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.5"
    }
    utils = {
      source  = "cloudposse/utils"
      version = "~> 2.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3"
    }
  }
}
