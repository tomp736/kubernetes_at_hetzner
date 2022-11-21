# ./main.tf

module "hetzner_network" {
  source = "./modules/network"

  network_ip_range = "10.98.0.0/16"
  network_subnet_ranges = [
    "10.98.0.0/24"
  ]
}

module "hetzner_nodes" {
  for_each = { for node in local.nodes : node.id => node }

  source          = "./modules/node"
  config_filepath = each.value.config_filepath
  subnet_id       = module.hetzner_network.hetzner_subnets["10.98.0.0/24"].id
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
[master]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "master"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[worker]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "worker"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[proxy]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "proxy"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}
  EOT
  filename = "secrets/main_inventory"
}