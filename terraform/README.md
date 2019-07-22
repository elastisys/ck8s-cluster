## Quickstart


* Download latest release of the exoscale provider from
<https://github.com/exoscale/terraform-provider-exoscale/releases>
* Move executable to `~/.terraform.d/plugins`
* Change directory to the cluster you want to manage (`system-services` or
`customer`)
* Set terraform token in ~/.terraformrc 
```
echo "credentials \"app.terraform.io\" {
 token = \"xxx\"
}" > ~/.terraformrc
```
* Run `terraform init`
* Set ~/.ssh/exoscale.pub specific for your cluster 
    * Can be created by following this link
    https://community.exoscale.com/documentation/compute/ssh-keypairs/
* Set env
```
TF_VAR_exoscale_api_key=xxx
TF_VAR_exoscale_secret_key=yyy
TF_VAR_ssh_pub_key_file=~/.ssh/exoscale.pub
```
* Apply with `terraform apply`
