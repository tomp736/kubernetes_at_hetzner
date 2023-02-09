# ./locals.tf

locals {
  config = jsondecode(file("files/config.json"))

  config_networks = { for network in local.config.networks : network.id => network }

  config_nodes_bastion = { for node in local.config.nodes : node.id => node if node.nodetype == "bastion" }
  config_nodes_metrics = { for node in local.config.nodes : node.id => node if node.nodetype == "metrics" }
  config_nodes_haproxy = { for node in local.config.nodes : node.id => node if node.nodetype == "haproxy" }
  config_nodes_master  = { for node in local.config.nodes : node.id => node if node.nodetype == "master" }
  config_nodes_worker  = { for node in local.config.nodes : node.id => node if node.nodetype == "worker" }
}