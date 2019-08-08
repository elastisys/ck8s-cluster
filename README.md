Elastisys Compliant Kubernetes A1 demo
======================================

# Overview

The Elastisys Compliant Kubernetes (ECK) A1 demo platform runs two Kubernetes
clusters. One called "system services" and one called "customer".

The system service cluster provides observability, log aggregation,
private container registry with vulnerability scanning and authentication using
the following services:
* Prometheus and Grafana
* Elasticsearch and Kibana
* Harbor
* Dex

The customer cluster manages the customer applications as well as providing
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

## Cloud infrastructure

Begin with setting up the cloud infrastructure using Terraform.
    export TF_VAR_exoscale_api_key=<xxx>
    export TF_VAR_exoscale_secret_key=<xxx>
    export TF_VAR_ssh_pub_key_file=<Path to pub key>
        
    cd ./terraform/system-services
    terraform workspace select <Name>
    terraform init
    terraform apply

    cd ./terraform/customer
    terraform workspace select <Name>
    terraform init
    terraform apply

Obs if using a new workspace visit https://app.terraform.io -> settings -> general setting
and change executing mode from "Remote" to "Local"

## Kubernetes clusters

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

    export ECK_SS_DOMAIN=<name-ss>.compliantkubernetes.com
    export ECK_C_DOMAIN=<name-c>.compliantkubernetes.com

    ./scripts/gen-rke-conf-ss.sh > ./eck-ss.yaml
    ./scripts/gen-rke-conf-c.sh > ./eck-c.yaml

    rke up --config ./eck-ss.yaml
    rke up --config ./eck-c.yaml

## Kubernetes resources

Lastly, create all of the Kubernetes resources in the clusters.
If the Oauth2 is to work a OAuth2 client need to be created in google under
APIs & Services -> credentials.
    
    export GOOGLE_CLIENT_ID=<xxx>
    export GOOGLE_CLIENT_SECRET=<xxx>

    export KUBECONFIG=$(pwd)/kube_config_eck-ss.yaml
    ./scripts/deploy-ss.sh

    export ECK_SS_KUBECONFIG=$(pwd)/kube_config_eck-ss.yaml
    export KUBECONFIG=$(pwd)/kube_config_eck-c.yaml
    ./scripts/deploy-c.sh

## DNS

Point `*.$ECK_DOMAIN` to the system services ~~elastic IP~~ worker IPs.

## Issues and limitations

Currently there is an issue where instances, that have been added to the EIP
loadbalancer pool (i.e. when they are no longer seen as unhealthy by the
healthchecks), can't reach the EIP.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030138

Sometimes EIPs are not possible to delete due to still being seen as having
attached instances.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030112
