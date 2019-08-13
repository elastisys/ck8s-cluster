## Helmfile 

https://github.com/roboll/helmfile

### Getting started
- Get Helmfile.

```
wget https://github.com/roboll/helmfile/releases/download/v0.80.2/helmfile_linux_amd64 -O helmfile
chmod +x helmfile
```

- Get helm `diff` plugin if not already installed.

```
helm plugin install https://github.com/databus23/helm-diff --version 2.11.0+5
```
### Environment variables
The following environment variables needs to be set in order to install all helm chart releases.
* `NFS_C_SERVER_IP`
* `NFS_SS_SERVER_IP`
* `ECK_C_DOMAIN`
* `ECK_SS_DOMAIN`
* `GOOGLE_CLIENT_ID`
* `GOOGLE_CLIENT_SECRET`
* `TF_VAR_exoscale_secret_key`
* `TF_VAR_exoscale_api_key`
* `CERT_TYPE`

### Helmfile environments
There is one environment for each cluster type:`system-services` and `customer`. 
Environemnts are specififed by using the flag `-e <environment_name>`. 


#### Check status

        helmfile -e customer -f helmfile.yaml status
        helmfile -e system-services -f helmfile.yaml status