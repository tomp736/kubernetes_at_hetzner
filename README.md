# awesome_kubernetes

No frills kubernetes cluster on hetzner cloud.

Requirements:

- terraform
- ansible
- hcloud_token
- access token to gitlab.labrats.work

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
terraform apply --var-file=default.tfvar
```

### Ansible will configure kubernetes nodes using generated inventory file

```bash
# apply-ansbile,sh
# install requirements and run playbook
cd ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventory site.yml
```
