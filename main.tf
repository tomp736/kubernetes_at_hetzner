# ./main.tf

module "networks" {
  for_each = local.all_networks
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/network?ref=main"


  network_name          = each.value.name
  network_ip_range      = each.value.ip_range
  network_subnet_ranges = each.value.subnet_ranges
}

module "cloud_init_configs" {
  for_each = local.all_nodes
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/cloud-init?ref=main"

  general = {
    hostname                   = each.value.name
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

module "nodes" {
  for_each = local.all_nodes
  source   = "git::https://github.com/labrats-work/modules-terraform.git//modules/hetzner/node?ref=main"

  node_config = each.value
  network_ids = [
    module.networks["default"].hetzner_network.id
  ]
  cloud_init_user_data = module.cloud_init_configs[each.key].user_data
}

resource "hcloud_server_network" "networks" {
  for_each = local.node_networks

  server_id = module.nodes[each.value.node].id
  subnet_id = values(module.networks[each.value.network].hetzner_subnets)[0].id
}

resource "null_resource" "test_connection" {
  for_each = local.all_nodes

  depends_on = [
    module.nodes
  ]

  connection {
    host         = hcloud_server_network.networks[format("%s%s", each.value.id, "bnet")].ip
    bastion_host = module.nodes[values(local.bastion_nodes)[0].id].ipv4_address
    agent        = true
    user         = "sysadmin"
    port         = "2222"
    type         = "ssh"
    timeout      = "5m"
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 60 && cloud-init status --wait"
    ]
    on_failure = continue
  }
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
    on_failure = continue
  }
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
[bastion]
%{for node in module.nodes~}
%{if node.nodetype == "bastion"}${~node.name} ansible_host=${node.ipv4_address}%{endif}
%{~endfor}

[node:children]
master
worker
haproxy

[node:vars]
%{for node in module.nodes~}
%{if node.nodetype == "bastion"}bastion_host=${node.name}%{endif}
%{~endfor}

[master]
%{for node in module.nodes~}
%{if node.nodetype == "master"}${~node.name} ansible_host=${hcloud_server_network.networks[format("%s%s", node.name, "bnet")].ip}%{endif}
%{~endfor}

[worker]
%{for node in module.nodes~}
%{if node.nodetype == "worker"}${~node.name} ansible_host=${hcloud_server_network.networks[format("%s%s", node.name, "bnet")].ip}%{endif}
%{~endfor}

[haproxy]
%{for node in module.nodes~}
%{if node.nodetype == "haproxy"}${~node.name} ansible_host=${hcloud_server_network.networks[format("%s%s", node.name, "bnet")].ip}%{endif}
%{~endfor}
  EOT
  filename = "ansible/inventory/hosts"
}

resource "local_file" "ansible_host_vars" {
  for_each = local.bastion_nodes
  content  = <<-EOT
bastion_host: ""
  EOT
  filename = "ansible/host_vars/${each.value.name}/ansible_ssh.yml"
}