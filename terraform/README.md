## First time setup


* Create a [terraform token](https://app.terraform.io/app/settings/tokens) and store it in `~/.terraformrc`

```
echo "credentials \"app.terraform.io\" {
 token = \"xxx\"
}" > ~/.terraformrc
```

* Run `terraform init`
* Create or select workspace: `terraform workspace select <name>` or `terraform workspace new <name>`
    * If using a new workspace make sure the token set above is exported as `export TF_TOKEN=<xxx>`
      then run `bash set-execution-mode.sh`
* Set up ssh key
    * Create two new pairs with `ssh-keygen` one for the _workload cluster_ and one for the _service cluster_.
    * Run `ssh-add <path-to-private-key>` for both keys to add the new identities
* Get an API key and secret key from the [Exoscale portal](https://portal.exoscale.com) (Account -> API keys)
* Set env

```
TF_VAR_exoscale_api_key=xxx
TF_VAR_exoscale_secret_key=yyy
export TF_VAR_ssh_pub_key_sc=<Path to pub key for service cluster>
export TF_VAR_ssh_pub_key_wc=<Path to pub key for workload cluster>
```

* Apply with `terraform apply`
