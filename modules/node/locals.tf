locals {
  node_config      = jsondecode(file(var.config_filepath))
  hetzner          = local.node_config.hetzner
  cloud_init       = local.node_config.cloud_init
  cloud_init_users = { for inst in local.cloud_init.users : inst.username => inst }

  cloud_init_user_data = replace(yamlencode({

    timezone                   = "Europe/Warsaw"
    package_update             = true
    package_upgrade            = true
    package_reboot_if_required = true
    final_message              = "The system is finally up, after $UPTIME seconds"
    power_state = {
      mode      = "reboot"
      message   = "Finished cloud init. Rebooting."
      condition = true
    }
    users = [
      for node_user in local.cloud_init_users : merge(
        {
          name                = "${node_user.username}"
          shell               = "/bin/bash"
          ssh-authorized-keys = node_user.public_keys
        },
        node_user.username != "root" ? {
          sudo   = node_user.sudo
          groups = node_user.groups
          home   = "/home/${node_user.username}"
        } : {}
      )
    ]
    runcmd = [
      "mkdir -p /etc/ssh/sshd_config.d",
      "echo \"Port ${local.cloud_init.ssh_port}\" > /etc/ssh/sshd_config.d/90-defaults.conf",
      "semanage port -a -t ssh_port_t -p tcp ${local.cloud_init.ssh_port}"
    ]
  }), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}