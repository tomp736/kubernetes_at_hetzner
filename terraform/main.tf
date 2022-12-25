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

module "metrics_node_group" {
  source = "./modules/node_group"
  depends_on = [
    module.bastion_node_group
  ]
  nodes        = local.config_nodes_metrics
  bastion_host = values(module.bastion_node_group.nodes)[0].ipv4_address
  public_key   = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

module "haproxy_node_group" {
  source = "./modules/node_group"
  depends_on = [
    module.bastion_node_group
  ]
  nodes        = local.config_nodes_haproxy
  bastion_host = values(module.bastion_node_group.nodes)[0].ipv4_address
  public_key   = var.public_key
  networks_map = { for config_network in local.config_networks : config_network.id =>
    {
      name       = config_network.id,
      hetzner_id = module.networks[config_network.id].hetzner_network.id
    }
  }
}

resource "local_file" "ansible_inventory_site" {
  content = templatefile("files/templates/site.tftpl", {
    bastion_nodes = [for node in module.bastion_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
    master_nodes = [for node in module.master_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
    worker_nodes = [for node in module.worker_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
    metrics_nodes = [for node in module.metrics_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
    haproxy_nodes = [for node in module.haproxy_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
  })
  filename = "ansible_hosts_site"
}

resource "local_file" "ansible_inventory_cluster" {
  content = templatefile("files/templates/cluster.tftpl", {
    bastion_nodes = [for node in module.bastion_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
    master_nodes = [for node in module.master_node_group.nodes : {
      name         = node.name,
      ansible_host = node.networks[module.networks["bnet"].hetzner_network.id].ip
    }]
    worker_nodes = [for node in module.worker_node_group.nodes : {
      name         = node.name,
      ansible_host = node.networks[module.networks["bnet"].hetzner_network.id].ip
    }]
    metrics_nodes = [for node in module.metrics_node_group.nodes : {
      name         = node.name,
      ansible_host = node.networks[module.networks["bnet"].hetzner_network.id].ip
    }]
    haproxy_nodes = [for node in module.haproxy_node_group.nodes : {
      name         = node.name,
      ansible_host = node.ipv4_address
    }]
  })
  filename = "ansible_hosts_cluster"
}