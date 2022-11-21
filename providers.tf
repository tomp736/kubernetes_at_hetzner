# providers.tf

terraform {
  backend "local" {
    path = "terraform.tfstate"
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