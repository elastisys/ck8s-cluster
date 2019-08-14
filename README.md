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

## Requirements

- [terraform](https://www.terraform.io/downloads.html) (tested with 0.12.6)
- [exoscale provider for terraform](https://github.com/exoscale/terraform-provider-exoscale/releases) (tested with 0.11.0)
- [RKE](https://github.com/rancher/rke/releases) (tested with 0.2.7)
- [kubectl](https://github.com/kubernetes/kubernetes/releases) (tested with 1.15.2)
- [helm](https://github.com/helm/helm/releases) (tested with 2.14.3)

## Cloud infrastructure

See [terraform/README.md](terraform/README.md) for more details on the steps below.

Begin with setting up the cloud infrastructure using Terraform.

    export TF_VAR_exoscale_api_key=<xxx>
    export TF_VAR_exoscale_secret_key=<xxx>
    export TF_VAR_ssh_pub_key_file_ss=<Path to pub key for system services cluster>
    export TF_VAR_ssh_pub_key_file_c=<Path to pub key for customer cluster>

    cd ./terraform/system-services
    terraform init
    terraform workspace select <Name>
    terraform apply

    cd ./terraform/customer
    terraform init
    terraform workspace select <Name>
    terraform apply

Obs if using a new workspace visit https://app.terraform.io, click your workspace and go to settings -> general setting
and change executing mode from "Remote" to "Local".

## Kubernetes clusters

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

    export ECK_SS_DOMAIN=<name-ss>.compliantkubernetes.com
    export ECK_C_DOMAIN=<name-c>.compliantkubernetes.com

    ./scripts/gen-rke-conf-ss.sh > ./eck-ss.yaml
    ./scripts/gen-rke-conf-c.sh > ./eck-c.yaml

    rke up --config ./eck-ss.yaml
    rke up --config ./eck-c.yaml

## DNS

The Domain name for the SS/C-cluster need to be registered. For "compliantkubernetes.com"
or "compliantk8s.com" this can be done in aws route 53. Create a A record with
`*.<name-ss>.compliantkubernetes.com` and add the worker nodes IPs as values.
(do the same for the C-cluster)

The values should be replaces with the elastic IP once thats working correctly.

## Kubernetes resources

Lastly, create all of the Kubernetes resources in the clusters.
If the Oauth2 is to work a OAuth2 client need to be created in [google console](https://console.cloud.google.com/apis/credentials) under
APIs & Services -> credentials.

The certificates for the ingreses in the system can have either staging or productions certificates from letsencrypt. There is a limit to the number of production certificates we can get per week. So staging is recommended during development, but it will yield untrusted certificates. Note that docker will not trust Harbor with staging certs, so you can't push images to Harbor and pods can't pull images from Harbor.

    export GOOGLE_CLIENT_ID=<xxx>
    export GOOGLE_CLIENT_SECRET=<xxx>

    export CERT_TYPE=<prod|staging>

    export KUBECONFIG=$(pwd)/kube_config_eck-ss.yaml
    ./scripts/deploy-ss.sh

    export ECK_SS_KUBECONFIG=$(pwd)/kube_config_eck-ss.yaml
    export KUBECONFIG=$(pwd)/kube_config_eck-c.yaml
    ./scripts/deploy-c.sh

## Issues and limitations

Currently there is an issue where instances, that have been added to the EIP
loadbalancer pool (i.e. when they are no longer seen as unhealthy by the
healthchecks), can't reach the EIP.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030138

Sometimes EIPs are not possible to delete due to still being seen as having
attached instances.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030112
