# ./main.tf

module "networks" {
  for_each = local.config_networks
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network?ref=main"


  network_name          = each.value.name
  network_ip_range      = each.value.ip_range
  network_subnet_ranges = each.value.subnet_ranges
}

module "bastion_node_group" {
  source     = "./modules/node_group"
  nodes      = local.config_nodes_bastion
  public_key = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

module "master_node_group" {
  source = "./modules/node_group"
  depends_on = [
    module.bastion_node_group
  ]
  nodes        = local.config_nodes_master
  bastion_host = values(module.bastion_node_group.nodes)[0].ipv4_address
  public_key   = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

module "worker_node_group" {
  source = "./modules/node_group"
  depends_on = [
    module.bastion_node_group
  ]
  nodes        = local.config_nodes_worker
  bastion_host = values(module.bastion_node_group.nodes)[0].ipv4_address
  public_key   = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("files/templates/hosts.tftpl", {
    bastion_nodes = [for node in local.config_nodes_bastion : {
      name         = node.name,
      ansible_host = module.bastion_node_group.nodes[node.id].ipv4_address
    }]
    master_nodes = [for node in local.config_nodes_master : {
      name         = node.name
    }]
    worker_nodes = [for node in local.config_nodes_worker : {
      name         = node.name
    }]
  })
  filename = "ansible_hosts"
}