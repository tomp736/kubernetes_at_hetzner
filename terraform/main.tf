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
  networks = concat(
    [
      {
        name = "default"
        id   = module.networks["default"].hetzner_network.id
      }
    ],
    [
      for network in local.all_nodes[each.value.id].networks : {
        name = network
        id   = module.networks[network].hetzner_network.id
      }
    ]
  )
  cloud_init_user_data = module.cloud_init_configs[each.key].user_data
}

resource "null_resource" "test_connection" {
  for_each = local.all_nodes

  depends_on = [
    module.nodes
  ]

  connection {
    host         = module.nodes[each.value.id].networks[module.networks["bnet"].hetzner_network.id]
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
%{for node in local.bastion_nodes~}
${~node.name} ansible_host=${module.nodes[node.id].ipv4_address}
%{~endfor}

[node:children]
master
worker
haproxy

[node:vars]
%{for node in local.bastion_nodes~}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh sysadmin@${module.nodes[node.id].ipv4_address} -o Port=2222 -o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=30m -W %h:%p"'
%{~endfor}

[master]
%{for node in local.master_nodes~}
${~node.name} ansible_host=${module.nodes[node.id].networks[module.networks["bnet"].hetzner_network.id]}
%{~endfor}

[worker]
%{for node in local.worker_nodes~}
${~node.name} ansible_host=${module.nodes[node.id].networks[module.networks["bnet"].hetzner_network.id]}
%{~endfor}

[haproxy]
%{for node in local.haproxy_nodes~}
${~node.name} ansible_host=${module.nodes[node.id].networks[module.networks["bnet"].hetzner_network.id]}
%{~endfor}
  EOT
  filename = "ansible_hosts"
}