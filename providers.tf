# providers.tf

terraform {
  cloud {
    organization = "labrats-work"
    workspaces {
      name = "kubernetes_at_hetzner"
    }
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