## Helmfile 

https://github.com/roboll/helmfile

Some notes

* Currently only one helm state file is used containing the states for the helm releases for both the workload_cluster and service_cluster clusters. `Environments` are used to differentiate between the two. It should be investigated what the best practices are, like use sub-helmfiles etc.

* In `helmfile.yaml` the certificates used to communicate with tiller is set to `../certs/<cluster-type>/kube-system/certs/helm.*`. Could be specifed using env variables in the future, or ignored if the nessecary helm env variables already have been set.  

* The values that the charts are using are found in the `values` folder.


### Getting started
- Get `helmfile`.

```
wget https://github.com/roboll/helmfile/releases/download/v0.80.2/helmfile_linux_amd64 -O helmfile
chmod +x helmfile
```

- Get `helm-diff` plugin if not already installed.

```
helm plugin install https://github.com/databus23/helm-diff --version 2.11.0+5
```
### Environment variables
The following environment variables are used and needs to be set in order to install all available helm charts.
Note: These are required for explicit use with `helmfile`. All might not be required to run the deploy scripts!

* `NFS_WC_SERVER_IP`
* `NFS_SC_SERVER_IP`
* `ECK_WC_DOMAIN`
* `ECK_SC_DOMAIN`
* `GOOGLE_CLIENT_ID`
* `GOOGLE_CLIENT_SECRET`
* `TF_VAR_exoscale_secret_key`
* `TF_VAR_exoscale_api_key`
* `CERT_TYPE`
* `TLS_SKIP_VERIFY`
* `TLS_VERIFY`
* `OAUTH_ALLOWED_DOMAINS`
* `S3_ACCESS_KEY`
* `S3_SECRET_KEY`
* `S3_REGION`
* `S3_REGION_ENDPOINT`
* `S3_HARBOR_BUCKET_NAME`
* `S3_VELERO_BUCKET_NAME`

If any environment variable is not set helmfile will throw an error and the release will not be installed. 

### Helmfile environments
There is one environment for each cluster type:`service_cluster` and `workload_cluster`. 
Environments are specififed by using the flag `-e <environment_name>`.

### Usage


* Install all releases specified in a helm state file e.g. `helmfile.yaml`
   
    `helmfile -f helmfile.yaml apply`

* To only install a specific release labels can be used e.g. `app=cert-manger`
   
    `helmfile -f helmfile.yaml -l app=cert-manager apply`

* Remove a specific release
    
    `helmfile -f helmfile.yaml -l app=cert-manager destroy`

* Use a specific environment
    
    `helmfile -f helmfile.yaml -e workload_cluster apply`

* Check status of releases
   
    `helmfile -f helmfile.yaml status`