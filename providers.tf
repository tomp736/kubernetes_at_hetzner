# providers.tf

terraform {
  backend "local" {
    path = "secrets/terraform.tfstate"
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}