## First time setup


* Download latest release of the exoscale provider from
<https://github.com/exoscale/terraform-provider-exoscale/releases>
* Move executable to `~/.terraform.d/plugins`
* Change directory to the cluster you want to manage (`system-services` or
`customer`)
* Create a [terraform token](https://app.terraform.io/app/settings/tokens) and store it in `~/.terraformrc`

```
echo "credentials \"app.terraform.io\" {
 token = \"xxx\"
}" > ~/.terraformrc
```

* Run `terraform init`
* Create or select workspace: `terraform workspace select <name>` or `terraform workspace new <name>`
    * If using a new workspace visit https://app.terraform.io, click your workspace and go to settings -> general setting and change executing mode from "Remote" to "Local".
* Set up ssh key
    * Create a new pair with `ssh-keygen`
    * Run `ssh-add <path-to-private-key>` to add the new identity
* Get an API key and secret key from the [Exoscale portal](https://portal.exoscale.com) (Account -> API keys)
* Set env

```
TF_VAR_exoscale_api_key=xxx
TF_VAR_exoscale_secret_key=yyy
TF_VAR_ssh_pub_key_file=<Path-to-pub-key>
```

* Apply with `terraform apply`
