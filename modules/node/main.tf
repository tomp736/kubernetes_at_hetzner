resource "hcloud_server" "node" {
  # hetzner
  name        = local.hetzner.name
  location    = local.hetzner.location
  image       = local.hetzner.image
  server_type = local.hetzner.server_type

  # cloud-init
  user_data = "#cloud-config\n${local.cloud_init_user_data}"

  labels = {
    nodetype = local.hetzner.nodetype
  }

  connection {
    host    = self.ipv4_address
    agent   = true
    user    = local.cloud_init.users[0].username
    port    = local.cloud_init.ssh_port
    type    = "ssh"
    timeout = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
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

resource "hcloud_server_network" "node_network" {
  server_id = hcloud_server.node.id
  subnet_id = var.subnet_id
}