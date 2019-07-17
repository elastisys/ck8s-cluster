## Quickstart
* Download latest release of the exoscale provider from
<https://github.com/exoscale/terraform-provider-exoscale/releases`>
* Move executable to `~/.terraform.d/plugins`
* Run `terraform init`
* Set env
```
TF_VAR_exoscale_api_key=xxx
TF_VAR_exoscale_secret_key=yyy
TF_VAR_ssh_pub_key_file=~/.ssh/exoscale.pub
```
* Apply with `terraform apply`
