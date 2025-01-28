terraform {
  required_version = ">= 1.0.0"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0.0"
    }
  }
}
