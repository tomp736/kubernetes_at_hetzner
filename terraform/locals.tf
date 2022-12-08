# ./locals.tf

locals {
  config = jsondecode(file("files/config.json"))

  all_networks = { for network in local.config.networks : network.id => network }
  all_nodes    = { for node in local.config.nodes : node.id => node }

  bastion_nodes = { for node in local.config.nodes : node.id => node if node.nodetype == "bastion" }
  master_nodes  = { for node in local.config.nodes : node.id => node if node.nodetype == "master" }
  worker_nodes  = { for node in local.config.nodes : node.id => node if node.nodetype == "worker" }
  haproxy_nodes = { for node in local.config.nodes : node.id => node if node.nodetype == "haproxy" }
}