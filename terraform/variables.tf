# ./variables.tf

variable "hcloud_token" {
  description = "(Required) - The Hetzner Cloud API Token, can also be specified with the HCLOUD_TOKEN environment variable."
  type        = string
  sensitive   = true
}

variable "public_key" {
  description = "(Required) - Public key for testing."
  type        = string
  sensitive   = true
}