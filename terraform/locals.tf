# ./locals.tf

locals {
  config = jsondecode(file("files/config.json"))

  config_networks = { for network in local.config.networks : network.id => network }

  config_nodes_bastion = { for node in local.config.nodes : node.id => node if node.nodetype == "bastion" }
  config_nodes_master  = { for node in local.config.nodes : node.id => node if node.nodetype == "master" }
  config_nodes_worker  = { for node in local.config.nodes : node.id => node if node.nodetype == "worker" }

  all_nodes = { for node in local.config.nodes : node.id => node }

  haproxy_nodes = { for node in local.config.nodes : node.id => node if node.nodetype == "haproxy" }
}