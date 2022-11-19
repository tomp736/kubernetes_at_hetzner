output "hetzner_subnets" {
  description = "hetzner subnets"
  value       = { for subnet in var.network_subnet_ranges : subnet => hcloud_network_subnet.kubernetes_subnet[subnet] }
}