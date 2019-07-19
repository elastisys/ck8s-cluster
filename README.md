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

    cd ./terraform/system-services
    terraform init
    terraform apply

    cd ./terraform/customer
    terraform init
    terraform apply

## Kubernetes clusters

Next, install the Kubernetes clusters on the cloud infrastructure that
Terraform created.

    ./scripts/gen-rke-conf-ss.sh > ./eck-ss.yaml
    ./scripts/gen-rke-conf-c.sh > ./eck-c.yaml

    rke up --config ./eck-ss.yaml
    rke up --config ./eck-c.yaml

## Kubernetes resources

Lastly, create all of the Kubernetes resources in the clusters.

    export KUBECONFIG=$(pwd)/kube_config_eck-ss.yaml
    ./scripts/deploy-ss.sh

    export KUBECONFIG=$(pwd)/kube_config_eck-c.yaml
    ./scripts/deploy-c.sh
