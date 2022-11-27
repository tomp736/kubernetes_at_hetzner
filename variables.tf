variable "hcloud_token" {
  description = "(Required) - The Hetzner Cloud API Token, can also be specified with the HCLOUD_TOKEN environment variable."
  type        = string
  sensitive   = true
}
variable "tfcloud_token" {
  description = "(Required) - The Terraform Cloud API Token"
  type        = string
  sensitive   = true
}