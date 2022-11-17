provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "agones"
}

terraform {
  required_providers {
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = "~> 2.2.3"
    }
    helm = {
      source  = "registry.terraform.io/hashicorp/helm"
      version = "~> 2.7.1"
    }
    kubernetes = {
      source  = "registry.terraform.io/hashicorp/kubernetes"
      version = "~> 2.14.0"
    }
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}
