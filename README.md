# awesome_kubernetes

## Awesome repository for kubernetes cluster

Provisioned on hetzner cloud using ansible and terraform

Requirements:

- terraform
- ansible
- hcloud_token

Uses local backend unless otherwise specified in terraform.

---

## Usage

### Terraform will provision servers and create an inventory file

``` default.tfvars
# default.tfvars 
# tfvars file to set hcloud token.
hcloud_token = "{{ hcloud_token }}"
```

``` bash
# apply-tf,sh
terraform apply --var-file=secrets/main.tfvar
```

### Ansible will configure kubernetes nodes using generated inventory file

```bash
# apply-ansible,sh
# install requirements and run playbook
cp secrets/main_inventory ansible/inventory
cd ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventory site.yml
```
