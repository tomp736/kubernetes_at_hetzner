# ./locals.tf

locals {
  config = jsondecode(file("files/config.json"))

  all_networks = { for network in local.config.networks : network.id => network }
  all_nodes    = { for node in local.config.nodes : node.id => node }

  bastion_nodes = { for node in local.config.nodes : node.id => node if node.nodetype == "bastion" }
  master_nodes  = { for node in local.config.nodes : node.id => node if node.nodetype == "master" }
  worker_nodes  = { for node in local.config.nodes : node.id => node if node.nodetype == "worker" }
  haproxy_nodes = { for node in local.config.nodes : node.id => node if node.nodetype == "haproxy" }

  node_networks = { for net in flatten(
    [
      for node in local.config.nodes :
      [
        for node_net in setproduct([node.id], node.networks) :
        {
          node    = node_net[0],
          network = node_net[1]
        }
      ]
    ]
  ) : format("%s_%s", net.network_net.node) => net }
}