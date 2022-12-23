# ./variables.tf

variable "nodes" {
  description = "(Required) - Nodes configuration."
  type        = any
}

variable "bastion_host" {
  description = "(Optional) - Bastion host ip."
  type        = string
  default     = null
}

variable "public_key" {
  description = "(Required) - Public key."
  type        = string
  sensitive   = true
}

variable "networks_map" {
  description = "(Required) - Map of network names to ids."
  type = map(object(
    {
      name       = string
      hetzner_id = string
    }
  ))
}