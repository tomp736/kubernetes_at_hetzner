resource "hcloud_network" "kubernetes_network" {
  name     = var.cluster_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "kubernetes_subnet" {
  for_each = { for subnet in var.network_subnet_ranges : subnet => subnet }

  network_id   = hcloud_network.kubernetes_network.id
  type         = "server"
  network_zone = var.network_zone
  ip_range     = each.value
}