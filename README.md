Elastisys Compliant Kubernetes A1 demo
======================================

# Overview

The Elastisys Compliant Kubernetes (ECK) A1 demo platform runs two Kubernetes
clusters. One called "service" and one called "workload".

The _service cluster_ provides observability, log aggregation,
private container registry with vulnerability scanning and authentication using
the following services:

* Prometheus and Grafana
* Elasticsearch and Kibana
* Harbor
* Dex

The _workload cluster_ manages the customer applications as well as providing
intrusion detection, security policies, log forwarding and monitoring using the
following services:

* Falco
* Open Policy Agent
* Fluentd
* Prometheus


# Setup

The management of the ECK platform is separated into different stages,
Exoscale cloud infrastructure (terraform), Kubernetes cluster (rke) and
Kubernetes resources (helm, kubectl).

When first setting up the demo environment each stage needs to be done in
sequential order since they are dependent on each other. Once the initial
installation is done, each stage can be updated independently.


## Cloud providers

Currently we support two cloud providers: Exoscale and Safespring.
The main difference between them is in setting up the cloud infrastructure. We have one terraform folder for each provider. The rest of the setup is controlled by the environment variable `CLOUD_PROVIDER` which should be set to `exoscale` or `safespring`.


## Requirements

- [terraform](https://www.terraform.io/downloads.html) (tested with 0.12.6)
- [exoscale provider for terraform](https://github.com/exoscale/terraform-provider-exoscale/releases) (tested with 0.11.0)
- [RKE](https://github.com/rancher/rke/releases) (tested with 0.2.8)
- [kubectl](https://github.com/kubernetes/kubernetes/releases) (tested with 1.15.2)
- [helm](https://github.com/helm/helm/releases) (tested with 2.14.3)
- [helmfile](https://github.com/roboll/helmfile) (tested with v0.81.3)
- [helm-diff](https://github.com/databus23/helm-diff) (tested with 2.11.0+5)

Soft (recommended) requirements:

- [vault](https://www.vaultproject.io/downloads.html) (tested with v1.2.3)
- [s3cmd](https://s3tools.org/s3cmd) available directly in ubuntus repositories (tested with 2.0.1)

## Get environment from Vault

Configure the vault address: `export VAULT_ADDR=https://vault.eck.elastisys.se`
and log in to Vault: `vault login`.

Get environment data from vault:

```
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|exoscale|citycloud}

# Create folder structure
FOLDERS="ssh-keys rke infra env customer certs/service_cluster/kube-system/certs certs/workload_cluster/kube-system/certs"
for folder in ${FOLDERS}
do
    mkdir -p clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/${folder}
done

FILES="ssh-keys/id_rsa_sc ssh-keys/id_rsa_wc rke/kube_config_eck-sc.yaml
rke/kube_config_eck-wc.yaml env/env.sh customer/kubeconfig.yaml
certs/service_cluster/kube-system/certs/ca-key.pem
certs/service_cluster/kube-system/certs/ca.pem
certs/service_cluster/kube-system/certs/helm-key.pem
certs/service_cluster/kube-system/certs/helm.pem
certs/service_cluster/kube-system/certs/tiller-key.pem
certs/service_cluster/kube-system/certs/tiller.pem
certs/workload_cluster/kube-system/certs/ca-key.pem
certs/workload_cluster/kube-system/certs/ca.pem
certs/workload_cluster/kube-system/certs/helm-key.pem
certs/workload_cluster/kube-system/certs/helm.pem
certs/workload_cluster/kube-system/certs/tiller-key.pem
certs/workload_cluster/kube-system/certs/tiller.pem"
for file in ${FILES}
do
    vault kv get -field=base64-content eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file} | base64 --decode > clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file}
done
```

Access Kubernetes API:

```
# Service cluster
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-sc.yaml
# Workload cluster
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-wc.yaml
```

Use helm:

```
# Service cluster
source scripts/helm-env.sh kube-system clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/service_cluster/kube-system/certs "helm"
# Workload cluster
source scripts/helm-env.sh kube-system clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/workload_cluster/kube-system/certs "helm"
```

Set up the same environment variables that were used to deploy:

```
# Source all environment files
source clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/env/env.sh
source common-env.sh
source ${CLOUD_PROVIDER}-common-env.sh
# Set env vars for passwords from vault
source scripts/get-gen-secrets.sh
```


## Quick setup of a new environment

In order to setup a new Compliant Kubernetes cluster you will need to do the following.

Create 4 S3 buckets, one for each of Harbor, Velero, Elasticsearch and Influxdb.
If you have `s3cmd` configured, you can do something like this:

```
s3cmd mb s3://<harbor-bucket>
s3cmd mb s3://<velero-bucket>
s3cmd mb s3://<es-backup>
s3cmd mb s3://<influxdb-bucket>
```

Decide on a name for this environment, the cloud provider to use and add environment variables to the `env.sh` file.
More details on available variables and an example is available in `example-env.sh`.
The minimum you will need is documented here:

```
# Add these to env.sh
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|exoscale|citycloud}
export CERT_TYPE={prod|staging}

export S3_ACCESS_KEY=<exoscale_api_key>
export S3_SECRET_KEY=<exoscale_secret_key>
export S3_HARBOR_BUCKET_NAME=<harbor-bucket>
export S3_VELERO_BUCKET_NAME=<velero-bucket>
export S3_ES_BACKUP_BUCKET_NAME=<es-backup>
export S3_INFLUX_BUCKET_URL=s3://<influxdb-bucket>

# Cloud provider specific env. Add these to env.sh
# Exoscale
export TF_VAR_exoscale_api_key=<xxx>
export TF_VAR_exoscale_secret_key=<xxx>
# Safespring and Citycloud
export OS_USERNAME=<username>
export OS_PASSWORD=<password>
# You should also have AWS credentials in ~/.aws/credentials, or add these:
export AWS_ACCESS_KEY_ID=<xxx>
export AWS_SECRET_ACCESS_KEY=<xxx>
```

Save `env.sh` when you are done and `source` all environment files to set the environment variables:

```
# Source all environment files
source env.sh
source common-env.sh
source ${CLOUD_PROVIDER}-common-env.sh
```

Generate ssh-keys and folder structure:

```
# Create folder structure
FOLDERS="ssh-keys rke infra env certs customer"
for folder in ${FOLDERS}
do
    mkdir -p clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/${folder}
done

# Generate ssh-keys
ssh-keygen -q -N "" -f clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc
ssh-keygen -q -N "" -f clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc

# Add ssh-keys to agent:
ssh-add clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc
ssh-add clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc
```

Generate passwords and client secrets and store them in vault at https://vault.eck.elastisys.se.
The current convention is that secrets for a specific environment are stored under `eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/`.
This script also sets the passwords as environment variables to be used by other scripts.
Note that you have to be logged in to vault for this (`vault login`).

```
source scripts/get-gen-secrets.sh
```

### Phase 1 - Create infrastructure

Create the infrastructure using terraform.
See [terraform/README.md](terraform/README.md) for more details on this.

```
cd ./terraform/${CLOUD_PROVIDER}
terraform init
terraform workspace select ${ENVIRONMENT_NAME}
terraform apply
cd ../..
```

*Note:* if using a new workspace set execution mode to local by `export TF_TOKEN=xxx`
(should be located in ~/.terraformrc) and run `bash set-execution-mode.sh`.

*Note:* For citycloud we are not responsible for creating the infrastructure, they will provides us with VMs, loadbalancer, etc., though we do have access to the infrastructure (so far the infrastructure for Getinge).
After getting the VMs we must first manually create the `infra.json` file and then continue with the ansible playbook below to install docker and add some files.

When terraform is done, you need to create a JSON file with the details of the infrastructure:

```
./scripts/gen-infra.sh > clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json
```

If the base image used to create the virtual machines does not include docker, you will also need to install it first on all machines.
(This is currently the case for Safespring and Citycloud.)
This can be done with ansible like this:

```
# Set up a python environment with ansible:
pipenv install
pipenv shell

# Install docker on all nodes:
./scripts/generate-inventory.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json > ansible/hosts.ini
ansible-playbook -i ansible/hosts.ini ansible/playbook.yml
```

### Phase 2 - Install Kubernetes

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

```
./scripts/gen-rke-conf-sc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json > clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-sc.yaml
./scripts/gen-rke-conf-wc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json > clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-wc.yaml

rke up --config clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-sc.yaml
rke up --config clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-wc.yaml
```

### Phase 3 - Install services in the clusters

Install services using the deploy scripts:

```
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-sc.yaml
./scripts/deploy-sc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json

export ECK_SC_KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-sc.yaml
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-wc.yaml
./scripts/deploy-wc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json
```

The option `--interactive` mode can be used when running `deploy-wc/sc.sh` to decide whether or not you want to apply upgrades to helm charts.

### Store environment in Vault

You can use Vault to store all data about the environment securely.
This includes ssh-keys, passwords, IP addresses, etc.

Configure the vault address: `export VAULT_ADDR=https://vault.eck.elastisys.se`
and log in to Vault: `vault login`.

You can now store all the important credentials and state used so far in vault:
```
cp env.sh clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/env/env.sh
cd clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}
FILES="ssh-keys/* rke/* customer/* certs/service_cluster/kube-system/certs/* certs/workload_cluster/kube-system/certs/* env/*"
for file in ${FILES}
do
    cat ${file} | base64 | vault kv put eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file} base64-content=-
done
cd ../../..
```

## Customer access

The `deploy-wc.sh` script creates RBAC resources, namespaces and a kubeconfig-file (`clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/customer/kubeconfig.yaml`) to be used by the customer.
You can configure what namespaces should be created and which users that should get access using the following environment variables:

```
CUSTOMER_NAMESPACES="demo1 demo2 demo3" # default: demo
CUSTOMER_ADMIN_USERS="admin1@example.com admin2@example.com" # default: admin@example.com
```

The customer kubeconfig will be configured to use the first namespace by default.

## Delete environment from Vault

Delete secrets:

```
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|citycloud|exoscale}
FILES="ssh-keys/id_rsa_sc ssh-keys/id_rsa_wc rke/kube_config_eck-sc.yaml
rke/kube_config_eck-wc.yaml env/env.sh
customer/kubeconfig.yaml
grafana
harbor
influxdb
kubelogin_client
grafana_client
dashboard_client
certs/service_cluster/kube-system/certs/ca-key.pem
certs/service_cluster/kube-system/certs/ca.pem
certs/service_cluster/kube-system/certs/helm-key.pem
certs/service_cluster/kube-system/certs/helm.pem
certs/service_cluster/kube-system/certs/tiller-key.pem
certs/service_cluster/kube-system/certs/tiller.pem
certs/workload_cluster/kube-system/certs/ca-key.pem
certs/workload_cluster/kube-system/certs/ca.pem
certs/workload_cluster/kube-system/certs/helm-key.pem
certs/workload_cluster/kube-system/certs/helm.pem
certs/workload_cluster/kube-system/certs/tiller-key.pem
certs/workload_cluster/kube-system/certs/tiller.pem"

# Delete just data for the current version
for file in ${FILES}
do
    vault kv delete eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file}
done

# Delete everything: metadata and all versions
for file in ${FILES}
do
    vault kv metadata delete eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file}
done
```

## DNS

The dns-name will be automatically created with the name `<dns_prefix>-wc/sc.a1ck.io` for exoscale and `<dns_prefix>-wc/sc.elastisys.se` for safespring.
In exoscale we use exoscale's own dns features, while for safespring we use AWS.

For safespring the domain can be changed by setting the terraform variable `aws_dns_zone_id` to an id of another hosted zone
in aws route53.


## Setting up Google as identity provider for dex.

1. Go to the [Google console](https://console.cloud.google.com/) and create a project.

2. Go to the [Oauth consent screen](https://console.cloud.google.com/apis/credentials/consent) and name the application with the same name as the project of your google cloud project add the top level domain e.g. `elastisys.se` to Authorized domains.

3. Go to [Credentials](https://console.cloud.google.com/apis/credentials) and press `Create credentials` and select `OAuth client ID`.
Select `web application` and give it a name and add the URL to dex in the `Authorized Javascript origins` field, e.g. `dex.demo.elastisys.se`.
Add `<dex url>/callback` to Authorized redirect URIs field, e.g. `dex.demo.elastisys.se/callback`.


## OpenID Connect with kubectl

For using OpenID Connect with kubectl, see
[kubelogin/README.md](kubelogin/README.md).


## Vault

Vault can be used to store cluster specific resources such as kube configurations and rke states.
Vault is currently exposed at `https://vault.eck.elastisys.se`
Since vault is a key-value store, files will need to be stringified through the use of for example `base64`. Keep in mind the size of the value that you are trying to store. Certain backends have a per-key-value limit, e.g. 512KB is the limit when using [consul](https://www.consul.io/docs/faq.html#q-what-is-the-per-key-value-size-limitation-for-consul-39-s-key-value-store-).

You can interact with vault through either the [HTTP API](https://www.vaultproject.io/api/overview.html) or the [Vault CLI](https://www.vaultproject.io/docs/commands/).


Example using the HTTP API and the provided scripts:

    # API endpoint to where your secret will be stored.
    SECRET_PATH="eck/data/v1/first_customer/1/service_cluster/rkestate"

    RKESTATE=$(cat eck-sc.rkestate | base64 --wrap=0)

    tee payload.json <<EOF
    {
        "data": {
            "statefile": "$RKESTATE"
        }
    }
    EOF

    cat payload.json | ./scripts/vault-post.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$SECRET_PATH" | jq

    rm payload.json

    # To retrieve the secret

    ./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$SECRET_PATH" | jq -r '.data.data.statefile' | base64 --decode

Example using the CLI:

    SECRET_PATH="eck/v1/first_customer/1/service_cluster/rkestate"

    # To store secret
    cat eck-sc.rkestate | base64 | vault kv put $SECRET_PATH rkestate=-

    # To update secret - add and/or update keys/values.
    echo "Hello" | vault kv patch $SECRET_PATH other_key=-

    # To retrieve secret
    vault kv get -format=json $SECRET_PATH | jq -r '.data.data.rkestate' | base64 --decode
    # or
    vault kv get -field=rkestate $SECRET_PATH | base64 --decode

    # Retrieve specific version of secret
    vault kv get -format=json -version=2 $SECRET_PATH | jq '.data.data'

    # Delete latest version of secret
    vault kv delete $SECRET_PATH

    # Delete secret completely
    vault kv metadata delete $SECRET_PATH

## Managing S3 buckets with s3cmd

**Safespring:** See [docs](https://docs.safespring.com/storage/s3cmd/) for how to configure s3cmd for Safespring.

**Exoscale:** See [docs](https://community.exoscale.com/documentation/storage/quick-start/#setup) for how to configure s3cmd for Exoscale.

## Issues and limitations

Currently there is an issue where instances, that have been added to the EIP
loadbalancer pool (i.e. when they are no longer seen as unhealthy by the
healthchecks), can't reach the EIP.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030138

Sometimes EIPs are not possible to delete due to still being seen as having
attached instances.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030112

Currently cloud-init in RancherOS does not correctly handle when running with multiple network interfaces e.g. `eth0` and `eth1` - (privnet).
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030849

If you have multiple ssh-keys loaded you may get errors along the lines of "Too many authentication failures" when running ansible or RKE.
To solve this you can list and delete unnecessary entries:

```
# List all loaded keys
ssh-add -l
# Delete a specific key form the list (note that this does not delete the actual file)
ssh-add -d /path/to/key
# Delete all keys from the list (this does not delete the actual files)
ssh-add -D
```

As of yet it is not possible to change the default vaule of the **elastic** user that the elastisearch operator creates.
See https://github.com/elastic/cloud-on-k8s/issues/967
