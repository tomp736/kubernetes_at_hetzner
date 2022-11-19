output "ipv4_address" {
  value = hcloud_server.node.ipv4_address
}
output "name" {
  value = local.hetzner.name
}
output "nodetype" {
  value = local.hetzner.nodetype
}