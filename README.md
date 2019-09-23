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

The management of the ECK A1 demo platform is separated into different stages,
Exoscale cloud infrastructure (terraform), Kubernetes cluster (rke) and
Kubernetes resources (helm, kubectl).

When first setting up the demo environment each stage needs to be done in
sequential order since they are dependent on each other. Once the initial
installation is done, each stage can be updated independently.

## Requirements

- [terraform](https://www.terraform.io/downloads.html) (tested with 0.12.6)
- [exoscale provider for terraform](https://github.com/exoscale/terraform-provider-exoscale/releases) (tested with 0.11.0)
- [RKE](https://github.com/rancher/rke/releases) (tested with 0.2.8)
- [kubectl](https://github.com/kubernetes/kubernetes/releases) (tested with 1.15.2)
- [helm](https://github.com/helm/helm/releases) (tested with 2.14.3)
- [helmfile](https://github.com/roboll/helmfile) (tested with v0.81.3)
- [helm-diff](https://github.com/databus23/helm-diff) (tested with 2.11.0+5)

## Cloud infrastructure

See [terraform/README.md](terraform/README.md) for more details on the steps below.

Begin with setting up the cloud infrastructure using Terraform.

    export AWS_ACCESS_KEY_ID=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export AWS_SECRET_ACCESS_KEY=<xxx> (not needed if credentials are located in ~/.aws/credentials)
    export TF_VAR_exoscale_api_key=<xxx>
    export TF_VAR_exoscale_secret_key=<xxx>
    export TF_VAR_ssh_pub_key_file_sc=<Path to pub key for service cluster>
    export TF_VAR_ssh_pub_key_file_wc=<Path to pub key for workload cluster>
    export TF_VAR_dns_prefix=<xxx>

    cd ./terraform
    terraform init
    terraform workspace select <Name>
    terraform apply
    

Obs if using a new workspace set execution mode to local by `export TF_TOKEN=xxx` 
(should be located in ~/.terraformrc) and run `bash set-execution-mode.sh`. 

The commands listed above will set up the cloud infrastructure using a "default" configuration. Changing the number of machines and thier size can be done by exporting the following values before running `terraform apply`.

    export TF_VAR_sc_master_count=<x | default 1>
    export TF_VAR_sc_master_size=<x | default "Large">
    
    export TF_VAR_wc_master_count=<x | default 1>
    export TF_VAR_wc_master_size=<x | default "Large">


## Kubernetes clusters

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

    ./scripts/gen-infra.sh > infra.json

    export ECK_SC_DOMAIN=$(cat infra.json | jq -r '.service_cluster.dns_name' | sed 's/[^.]*[.]//')
    export ECK_WC_DOMAIN=$(cat infra.json | jq -r '.workload_cluster.dns_name' | sed 's/[^.]*[.]//')

    ./scripts/gen-rke-conf-sc.sh infra.json  > eck-sc.yaml
    ./scripts/gen-rke-conf-wc.sh infra.json > eck-wc.yaml

    rke up --config eck-sc.yaml
    rke up --config eck-wc.yaml

## DNS

The dns-name will be automatically created with the name `<dns_prefix>-wc/sc.compliantkubernetes.com`.
The domain can be changed by setting the terraform variable `aws_dns_zone_id` to an id of another hosted zone
in aws route53.

## Setting up Google as identity provider for dex.

1. Go to GCP and create a project. 
Select `APIs &Services` in the menu.

2. Select `Oauth consent screen` and name the application with the same name as the project of your google cloud project add the top level domain e.g. `compliantkubernetes.com` to Authorized domains. 

3. Go to `Credentials` and press `Create credentials` and select `OAuth client ID`. 
Select `web application` and give it a name and add the URL to dex in the `Authorized Javascript origins` field, e.g. `dex.demo.compliantkubernetes.com`.
Add `<dex url>/callback` to Authorized redirect URIs field, e.g. `dex.demo.compliantkubernetes.com/callback`

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

    # For harbor image chart storage
    export S3_ACCESS_KEY=<exoscale_api_key>
    export S3_SECRET_KEY=<exoscale_secret_key>
    export S3_REGION=de-fra-1
    export S3_REGION_ENDPOINT=https://sos-de-fra-1.exo.io
    export S3_BUCKET_NAME=harbor-bucket

    export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
    ./scripts/deploy-sc.sh infra.json <--interactive>

    export ECK_SC_KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
    export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
    ./scripts/deploy-wc.sh infra.json <--interactive>

## OpenID Connect with kubectl

For using OpenID Connect with kubectl, see
[kubelogin/README.md](kubelogin/README.md).

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
