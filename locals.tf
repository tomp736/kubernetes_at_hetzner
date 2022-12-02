# ./locals.tf

locals {
  config   = jsondecode(file("files/config.json"))
  networks = local.config.networks
  nodes    = local.config.nodes
}