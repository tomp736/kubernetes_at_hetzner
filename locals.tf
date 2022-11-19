locals {
  nodes = [
    {
      id              = "c0m0",
      config_filepath = "${path.module}/files/c0m0_config.json"
    },
    {
      id              = "c0w0",
      config_filepath = "${path.module}/files/c0w0_config.json"
    }
  ]
}