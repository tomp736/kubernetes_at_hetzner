# ./main.tf

module "network" {
  source = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network"

  network_ip_range = "10.98.0.0/16"
  network_subnet_ranges = [
    "10.98.0.0/24"
  ]
}

module "cloud-init" {
  for_each = { for node in local.config.nodes : node.id => node }
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/cloud-init"
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExbodob3iNOPTRsZms/Gjp8PTWnU5fqc1TJEKpTLXIA u0@s01",
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDxJpolhuDKTr4KpXnq5gPTKYUnoKyAnpIR4k5m3XCH u0@prt-dev-01",
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwIzhRR2PLaScPBSBS2cfN9dthkdiB5ZvhkFNMpT+6G u0@prt-dev-01",
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgBAq+CCGT/of2ROoB1+1NiYqrWSSKrptvD7D7NIYM8 gitlab@gitlab.labrats.work"
      ]
    }
  ]
  runcmd = [
    "mkdir -p /etc/ssh/sshd_config.d",
    "echo \"Port 2222\" > /etc/ssh/sshd_config.d/90-defaults.conf"
  ]
}

module "hetzner_nodes" {
  for_each = { for node in local.config.nodes : node.id => node if node.hetzner != null }

  source               = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/node"
  node_config_json     = jsonencode(each.value)
  cloud_init_user_data = module.cloud-init[each.key].user_data
}

resource "hcloud_server_network" "kubernetes_subnet" {
  for_each = { for node in local.config.nodes : node.id => node }

  server_id = module.hetzner_nodes[each.key].id
  subnet_id = module.network.hetzner_subnets["10.98.0.0/24"].id
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
  filename = "ansible/inventory"
}

resource "local_file" "node_ips" {
  content  = <<-EOT
%{for node in module.hetzner_nodes~}
${node.ipv4_address}
%{~endfor~}
  EOT
  filename = "node_ips"
}