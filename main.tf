# ./main.tf

module "hetzner_network" {
  for_each = { for network in local.networks : network.id => network if network.hetzner != null }  
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network?ref=main"


  network_name          = each.value.hetzner.name
  network_ip_range      = each.value.hetzner.ip_range
  network_subnet_ranges = each.value.hetzner.subnet_ranges
}

module "cloud-init" {
  for_each = { for node in local.nodes : node.id => node if node.hetzner != null }
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/cloud-init?ref=main"

  general = {
    hostname                   = each.value.hetzner.name
    package_reboot_if_required = true
    package_update             = true
    package_upgrade            = true
    timezone                   = "Europe/Warsaw"
  }
  users_data = [
    {
      name  = "sysadmin"
      shell = "/bin/bash"
      ssh-authorized-keys = [
        var.public_key,
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDxJpolhuDKTr4KpXnq5gPTKYUnoKyAnpIR4k5m3XCH u0@prt-dev-01"
      ]
    }
  ]
  runcmd = [
    "mkdir -p /etc/ssh/sshd_config.d",
    "echo \"Port 2222\" > /etc/ssh/sshd_config.d/90-defaults.conf"
  ]
}

module "hetzner_nodes" {
  for_each = { for node in local.nodes : node.id => node if node.hetzner != null }
  source               = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/node?ref=main"

  node_config          = each.value.hetzner
  cloud_init_user_data = module.cloud-init[each.key].user_data
}

resource "hcloud_server_network" "kubernetes_subnet" {
  for_each = { for node in local.nodes : node.id => node }

  server_id = module.hetzner_nodes[each.key].id
  subnet_id = values(module.hetzner_network)[0].hetzner_subnets["10.98.0.0/24"].id
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
[bastion]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "bastion"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[node:children]
master
worker
haproxy

[node:vars]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "bastion"}bastion_host=${node.ipv4_address}%{endif}
%{~endfor~}

[master]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "master"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[worker]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "worker"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}

[haproxy]
%{for node in module.hetzner_nodes~}
%{if node.nodetype == "haproxy"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor~}
  EOT
  filename = "ansible/inventory/hosts"
}

resource "local_file" "ansible_host_vars" {
  for_each = { for node in local.nodes : node.id => node if node.hetzner != null && node.hetzner.nodetype == "bastion" }  
  content  = <<-EOT
bastion_host: ""
  EOT
  filename = "ansible/host_vars/${module.hetzner_nodes[each.key].hetzner.name}/ansible_ssh.yml"
}