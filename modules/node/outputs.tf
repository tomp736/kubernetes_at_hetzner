output "ipv4_address" {
  value     = hcloud_server.node.ipv4_address
  sensitive = true
}
output "name" {
  value     = local.hetzner.name
  sensitive = true
}
output "nodetype" {
  value = local.hetzner.nodetype
}