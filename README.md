# Kubernetes@Hetzner

[![Terraform Test E2E](https://github.com/tomp736/kubernetes_at_hetzner/actions/workflows/test-e2e.yml/badge.svg)](https://github.com/tomp736/kubernetes_at_hetzner/actions/workflows/test-e2e.yml)

Kubernetes cluster provisioned on hetzner cloud using ansible and terraform.

---

## Usage

### Terraform creates hetzners resources and generates an inventory for ansible.

``` default.tfvars
# default.tfvars 
# tfvars file to set hcloud token.
hcloud_token = "{{ hcloud_token }}"
```

``` bash
# apply-tf,sh
terraform apply --var-file=secrets/main.tfvar
```

### Ansible configures kubernetes using generated inventory.

```bash
# apply-ansible,sh
# install requirements and run playbook
cp secrets/main_inventory ansible/inventory
cd ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventory site.yml
```
