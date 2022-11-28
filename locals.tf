locals {
  nodes = jsondecode(file("files/node_config.json"))
}