# ./main.tf

module "network" {
  source = "./modules/network"

  network_ip_range = "10.98.0.0/16"
  network_subnet_ranges = [
    "10.98.0.0/24"
  ]
}

module "nodes" {
  for_each = { for node in local.nodes : node.id => node }

  source          = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/node"
  config_filepath = each.value.config_filepath
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
[master]
%{for node in module.nodes~}
%{if node.nodetype == "master"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[worker]
%{for node in module.nodes~}
%{if node.nodetype == "worker"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[proxy]
%{for node in module.nodes~}
%{if node.nodetype == "proxy"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}
  EOT
  filename = "secrets/main_inventory"
}

resource "local_file" "node_ips" {
  content  = <<-EOT
%{for node in module.nodes~}
${node.ipv4_address}
%{~endfor~}
  EOT
  filename = "node_ips"
}