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

## Get environment from Vault

Get environment data from vault:

```
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|exoscale|citycloud}

# Create folder structure
FOLDERS="ssh-keys rke infra env certs/service_cluster/kube-system/certs certs/workload_cluster/kube-system/certs"
for folder in ${FOLDERS}
do
    mkdir -p clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/${folder}
done

FILES="ssh-keys/id_rsa_sc ssh-keys/id_rsa_wc rke/kube_config_eck-sc.yaml rke/kube_config_eck-wc.yaml env/env.sh certs/service_cluster/kube-system/certs/ca-key.pem certs/service_cluster/kube-system/certs/ca.pem certs/service_cluster/kube-system/certs/helm-key.pem certs/service_cluster/kube-system/certs/helm.pem certs/service_cluster/kube-system/certs/tiller-key.pem certs/service_cluster/kube-system/certs/tiller.pem certs/workload_cluster/kube-system/certs/ca-key.pem certs/workload_cluster/kube-system/certs/ca.pem certs/workload_cluster/kube-system/certs/helm-key.pem certs/workload_cluster/kube-system/certs/helm.pem certs/workload_cluster/kube-system/certs/tiller-key.pem certs/workload_cluster/kube-system/certs/tiller.pem"
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

## Quick setup of a new environment

In order to setup a new Compliant Kubernetes cluster you will need to do the following.

Decide on a prefix for this environment, the cloud provider to use and add common environment variables:

```
# Add these to env.sh
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|exoscale|citycloud}

# Cloud provider specific env. Add these to env.sh
# Exoscale
export TF_VAR_exoscale_api_key=<xxx>
export TF_VAR_exoscale_secret_key=<xxx>
export S3_ACCESS_KEY=<exoscale_api_key>
export S3_SECRET_KEY=<exoscale_secret_key>
# Safespring and Citycloud
export OS_USERNAME=<username>
export OS_PASSWORD=<password>
# You should also have AWS credentials in ~/.aws/credentials, or add these:
export AWS_ACCESS_KEY_ID=<xxx>
export AWS_SECRET_ACCESS_KEY=<xxx>

# Source all environment files
source env.sh
source common-env.sh
source ${CLOUD_PROVIDER}-common-env.sh
```

Generate ssh-keys and folder structure:

```
# Create folder structure
FOLDERS="ssh-keys rke infra env certs"
for folder in ${FOLDERS}
do
    mkdir -p clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/${folder}
done

# Generate ssh-keys
ssh-keygen -q -N "" -f clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc
ssh-keygen -q -N "" -f clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc
```

Create the infrastructure using terraform:

```
cd ./terraform/${CLOUD_PROVIDER}
terraform init
terraform workspace select ${ENVIRONMENT_NAME}
terraform apply
cd ../..
```

*Note:* if using a new workspace set execution mode to local by `export TF_TOKEN=xxx`
(should be located in ~/.terraformrc) and run `bash set-execution-mode.sh`.

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

# Add ssh-keys to agent:
ssh-add clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc

# Install docker on all nodes:
./scripts/generate-inventory.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json > ansible/hosts.ini
ansible-playbook -i ansible/hosts.ini ansible/playbook.yml
```

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

```
export ECK_SC_DOMAIN=${ENVIRONMENT_NAME}-sc.elastisys.se
export ECK_WC_DOMAIN=${ENVIRONMENT_NAME}-wc.elastisys.se

./scripts/gen-rke-conf-sc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json  > clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-sc.yaml
./scripts/gen-rke-conf-wc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json > clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-wc.yaml

rke up --config clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-sc.yaml
rke up --config clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/eck-wc.yaml
```

Install services:

```
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-sc.yaml
./scripts/deploy-sc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json

export ECK_SC_KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-sc.yaml
export KUBECONFIG=$(pwd)/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/rke/kube_config_eck-wc.yaml
./scripts/deploy-wc.sh clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/infra/infra.json
```

You can use Vault to store all data about the environment securely.
This includes ssh-keys, passwords, IP addresses, etc.

Configure the vault address: `export VAULT_ADDR=https://vault.eck.elastisys.se`
and log in to Vault: `vault login`.

You can now store all the important credentials and state used so far in vault:
```
cp env.sh clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/env/env.sh
cd clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}
FILES="ssh-keys/* rke/* certs/service_cluster/kube-system/certs/* certs/workload_cluster/kube-system/certs/* env/*"
for file in ${FILES}
do
    cat ${file} | base64 | vault kv put eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file} base64-content=-
done
cd ../../..
```

## Delete environment from Vault

Delete secrets:

```
export ENVIRONMENT_NAME=test
export CLOUD_PROVIDER={safespring|citycloud|exoscale}
FILES="ssh-keys/id_rsa_sc ssh-keys/id_rsa_wc rke/kube_config_eck-sc.yaml rke/kube_config_eck-wc.yaml env/env.sh certs/service_cluster/kube-system/certs/ca-key.pem certs/service_cluster/kube-system/certs/ca.pem certs/service_cluster/kube-system/certs/helm-key.pem certs/service_cluster/kube-system/certs/helm.pem certs/service_cluster/kube-system/certs/tiller-key.pem certs/service_cluster/kube-system/certs/tiller.pem certs/workload_cluster/kube-system/certs/ca-key.pem certs/workload_cluster/kube-system/certs/ca.pem certs/workload_cluster/kube-system/certs/helm-key.pem certs/workload_cluster/kube-system/certs/helm.pem certs/workload_cluster/kube-system/certs/tiller-key.pem certs/workload_cluster/kube-system/certs/tiller.pem"

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

## Cloud infrastructure

See [terraform/README.md](terraform/README.md) for more details on the steps below.

Begin with setting up the cloud infrastructure using Terraform.

For exoscale:

    export AWS_ACCESS_KEY_ID=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export AWS_SECRET_ACCESS_KEY=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export TF_VAR_exoscale_api_key=<xxx>
    export TF_VAR_exoscale_secret_key=<xxx>
    export TF_VAR_ssh_pub_key_file_sc=<Path to pub key for service cluster>
    export TF_VAR_ssh_pub_key_file_wc=<Path to pub key for workload cluster>
    export TF_VAR_dns_prefix=<xxx>

    export CLOUD_PROVIDER=exoscale

    cd ./terraform/exoscale
    terraform init
    terraform workspace select <Name>
    terraform apply

For safespring:

    export AWS_ACCESS_KEY_ID=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export AWS_SECRET_ACCESS_KEY=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export TF_VAR_ssh_pub_key_file_sc=<Path to pub key for service cluster>
    export TF_VAR_ssh_pub_key_file_wc=<Path to pub key for workload cluster>
    export TF_VAR_dns_prefix=<xxx>

    export OS_IDENTITY_API_VERSION=3
    export OS_AUTH_URL=https://keystone.api.cloud.ipnett.se/v3
    export OS_PROJECT_DOMAIN_NAME=elastisys.se
    export OS_USER_DOMAIN_NAME=elastisys.se
    export OS_PROJECT_NAME=infra.elastisys.se
    export OS_USERNAME=<username>
    export OS_PASSWORD=<password>
    export OS_REGION_NAME=se-east-1
    export OS_PROJECT_ID=9f91e56185fb4f929c36430ac4bcbe6e

    export CLOUD_PROVIDER=safespring

    cd ./terraform/safespring
    terraform init
    terraform workspace select <Name>
    terraform apply

For citycloud we are not responsible for creating the infrastructure, they will provides us with VMs, loadbalancer, etc. Though we do have access to the infrastructure (so far the infrastructure for Getinge). And after getting the VMs we must first manually create the `infra.json` file and then run an ansible script to install docker and add some files.

    export OS_USERNAME=<username>
    export OS_PASSWORD=<password>
    export OS_AUTH_URL=https://fra1.citycloud.com:5000
    export OS_USER_DOMAIN_NAME=CCP_Domain_37642
    export OS_PROJECT_DOMAIN_NAME=CCP_Domain_37642
    export OS_REGION_NAME=Fra1
    export OS_PROJECT_NAME="Spider"
    export OS_TENANT_NAME="Spider"
    export OS_AUTH_VERSION=3
    export OS_IDENTITY_API_VERSION=3
    export OS_PROJECT_ID=ba47a6b513b645dd94fa31ea5e2becbd

    export CLOUD_PROVIDER=citycloud

Obs if using a new workspace set execution mode to local by `export TF_TOKEN=xxx`
(should be located in ~/.terraformrc) and run `bash set-execution-mode.sh`.

The commands listed above will set up the cloud infrastructure using a "default" configuration. Changing the number of machines and thier size can be done by exporting the following values before running `terraform apply`.

    export TF_VAR_sc_master_count=<x | default 1>
    export TF_VAR_sc_master_size=<x | default "Large">

    export TF_VAR_wc_master_count=<x | default 1>
    export TF_VAR_wc_master_size=<x | default "Large">

    export TF_VAR_sc_nfs_size=<x | default "Medium">
    export TF_VAR_wc_nfs_size=<x | default "Medium">

When terraform is done, you need to create a JSON file with the details of the infrastructure:

    ./scripts/gen-infra.sh > infra.json

If the base image used to create the virtual machines does not include docker, you will also need to install it first on all machines.
(This is currently the case for Safespring and Citycloud.)
This can be done with ansible like this:

    # Set up a python environment with ansible:
    pipenv install
    pipenv shell

    # (Optional) If your ssh keys are not picked up by the authentication agent
    # you need to add them for ansible to be able to use them:
    ssh-add ${TF_VAR_ssh_pub_key_file_sc%.pub} ${TF_VAR_ssh_pub_key_file_wc%.pub}

    # Install docker on all nodes:
    ./scripts/generate-inventory.sh infra.json > ansible/hosts.ini
    ansible-playbook -i ansible/hosts.ini ansible/playbook.yml

## Service passwords - optional

Once the cloud infrastructure is running it is time to generate and store passwords in vault for some of the services.

Begin by getting a hold of a vault token. (Most likley via the elastisys secrets repo)
Set the environment variables

    export CUSTOMER_ID=<the customer identifier>
    export VAULT_ADDR=<the url to vault | https://vault.eck.elastisys.se>
    export VAULT_TOKEN=<...>
    export PWD_LENGTH=<desired length for the passwords>

The secrets for a given customer should be stored at the path `eck/v1/${CUSTOMER_ID}/1/*`.
To use the a more correct terminology the _path_ really is `v1/${CUSTOMER_ID}/1/*`, while `eck/` is the location of the secrets engine used - [KV v2](https://www.vaultproject.io/api/secret/kv/kv-v2.html).

The `1` can be used to reference secrets in different eck clusters if a customer happens to have more than just one.
If a customer has more than one eck cluster than the `1` can be changed accordingly to reference the correct cluster.
The API endpoint for KV v2 is `eck/data/<path>`. Therefore to write secrets to `eck/v1/${CUSTOMER_ID}/1/*`, the API endpoint becomes `eck/data/v1/${CUSTOMER_ID}/1/*`.
The passwords for the services will be located at `eck/v1/${CUSTOMER_ID}/1/{service_name}` with the key `password`.
The environment variable `BASE_PATH` is used to reference the API endpoint excluding the name of the service to store password for.

Set the following environment variable

    export BASE_PATH=<"eck/data/v1/${CUSTOMER_ID}/1">

To generate and store the passwords for the services - `grafana`, `harbor`, and `influxdb` - execute the following command

    ./scripts/store-pwds.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$PWD_LENGTH" "$BASE_PATH" "grafana" "influxdb" "harbor"

If you do not want to generate passwords for a certain service then simply remove it from command above.

Now the passwords have been generated and stored in vault!


To use the generated password for the services run the following commands to fetch the passwords and export them as environment variables

    # Get grafana password
    export GRAFANA_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/grafana" | jq -r '.data.data.password')

    # Get harbor password
    export HARBOR_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/harbor" | jq -r '.data.data.password')

    # Get influxdb password
    export INFLUXDB_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/influxdb" | jq -r '.data.data.password')

**Note**: As of yet it is not possible to change the default vaule of the **elastic** user that the elastisearch operator creates. See https://github.com/elastic/cloud-on-k8s/issues/967


## Kubernetes clusters

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

    export ECK_SC_DOMAIN=$(cat infra.json | jq -r '.service_cluster.dns_name' | sed 's/[^.]*[.]//')
    export ECK_WC_DOMAIN=$(cat infra.json | jq -r '.workload_cluster.dns_name' | sed 's/[^.]*[.]//')

    ./scripts/gen-rke-conf-sc.sh infra.json  > eck-sc.yaml
    ./scripts/gen-rke-conf-wc.sh infra.json > eck-wc.yaml

    rke up --config eck-sc.yaml
    rke up --config eck-wc.yaml

To create a cluster without PodSecurityPoslicy, OPA, and Harbor set the environments variables `ENABLE_PSP`, `ENABLE_OPA`, `ENABLE_HARBOR` to `false`.


## DNS

The dns-name will be automatically created with the name `<dns_prefix>-wc/sc.a1ck.io` for exoscale and `<dns_prefix>-wc/sc.elastisys.se` for safespring.
In exoscale we use exoscale's own dns features, while for safespring we use AWS.

For safespring the domain can be changed by setting the terraform variable `aws_dns_zone_id` to an id of another hosted zone
in aws route53.


## Setting up Google as identity provider for dex.

1. Go to GCP and create a project.
Select `APIs &Services` in the menu.

2. Select `Oauth consent screen` and name the application with the same name as the project of your google cloud project add the top level domain e.g. `elastisys.se` to Authorized domains.

3. Go to `Credentials` and press `Create credentials` and select `OAuth client ID`.
Select `web application` and give it a name and add the URL to dex in the `Authorized Javascript origins` field, e.g. `dex.demo.elastisys.se`.
Add `<dex url>/callback` to Authorized redirect URIs field, e.g. `dex.demo.elastisys.se/callback`


## Kubernetes resources

Lastly, create all of the Kubernetes resources in the clusters.
If the Oauth2 is to work a OAuth2 client need to be created in [google console](https://console.cloud.google.com/apis/credentials) under
APIs & Services -> credentials.

The certificates for the ingresses in the system can have either staging or production certificates from letsencrypt.
There is a limit to the number of production certificates we can get per week. So staging is recommended during development, but it will yield untrusted certificates.
Note that docker will not trust Harbor with staging certs, so you can't push images to Harbor and pods can't pull images from Harbor.

The option `--interactive` mode can be used when running `deploy-wc/sc.sh` to decide whether or not you want to apply upgrades to helm charts.
The default is not to use that option.

There are two optional identity providers for dex: Google and A1 AAA.
You can activate them by setting environment variables with client ID and secret before running the deploy script as seen below.


    export GOOGLE_CLIENT_ID=<xxx>
    export GOOGLE_CLIENT_SECRET=<xxx>
    export AAA_CLIENT_ID=<xxx>
    export AAA_CLIENT_SECRET=<xxx>

    export CERT_TYPE=<prod|staging>

    # For harbor image chart storage and velero backup storage
    export S3_ACCESS_KEY=<exoscale_api_key>
    export S3_SECRET_KEY=<exoscale_secret_key>
    export S3_REGION=de-fra-1
    export S3_REGION_ENDPOINT=https://sos-de-fra-1.exo.io
    export S3_HARBOR_BUCKET_NAME=harbor-bucket
    export S3_VELERO_BUCKET_NAME=velero-bucket

    # Influx cronjob backup variables.
    export INFLUX_ADDR=influx.influxdb-prometheus.svc:8088
    export S3_INFLUX_BUCKET_URL=s3://influxdb-backups
    export INFLUX_BACKUP_SCHEDULE="0 0 * * *"

    export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
    ./scripts/deploy-sc.sh infra.json <--interactive>

    export ECK_SC_KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
    export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
    ./scripts/deploy-wc.sh infra.json <--interactive>

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


## Customer demo access

Set up customer access in a demo environment:

```
kubectl create ns demo
kubectl -n demo create rolebinding demo-admin --clusterrole=admin --user=admin@example.com
```

Generate kubeconfig for customer:

```
ENVIRONMENT_NAME=test
ECK_SC_DOMAIN=${ENVIRONMENT_NAME}-sc.elastisys.se
ECK_WC_DOMAIN=${ENVIRONMENT_NAME}-wc.elastisys.se
OIDC_ISSUER_URL=https://dex.${ECK_SC_DOMAIN}
OIDC_CLIENT_ID=kubernetes
OIDC_CLIENT_SECRET=ZXhhbXBsZS1hcHAtc2VjcmV0

KUBECONFIG=customer_kubeconfig.yaml
kubectl config set-cluster compliantk8s --server=https://${ECK_WC_DOMAIN}:6443
kubectl config set-credentials developer --exec-command=kubelogin \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=${OIDC_ISSUER_URL} \
  --exec-arg=--oidc-client-id=${OIDC_CLIENT_ID} \
  --exec-arg=--oidc-client-secret=${OIDC_CLIENT_SECRET} \
  --exec-arg=--oidc-extra-scope=email
kubectl config set-context developer@compliantk8s --user developer --cluster=compliantk8s --namespace=demo
kubectl config use-context developer@compliantk8s
```

Finally copy the `cluster` definition from `kube_config_eck-wc.yaml`.
Including `certificate-authority-data` and `server`.

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
