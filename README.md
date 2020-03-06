Elastisys Compliant Kubernetes
==============================

# Overview

The Elastisys Compliant Kubernetes (ck8s) platform runs two Kubernetes
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

The management of the ck8s platform is separated into different stages,
Exoscale cloud infrastructure (terraform), Kubernetes cluster (rke) and
Kubernetes resources (helm, kubectl).

When first setting up the environment each stage needs to be done in
sequential order since they are dependent on each other. Once the initial
installation is done, each stage can be updated independently.

## Cloud providers

Currently we support two cloud providers: Exoscale and Safespring.
The main difference between them is in setting up the cloud infrastructure. We have one terraform folder for each provider. The rest of the setup is controlled by the environment variable `CLOUD_PROVIDER` which should be set to `exoscale` or `safespring`.

## Requirements

- [terraform](https://www.terraform.io/downloads.html) (tested with 0.12.19)
- [RKE](https://github.com/rancher/rke/releases) (tested with 1.0.0)
- [kubectl](https://github.com/kubernetes/kubernetes/releases) (tested with 1.15.2)
- [helm](https://github.com/helm/helm/releases) (tested with 2.14.3)
- [helmfile](https://github.com/roboll/helmfile) (tested with v0.99.0)
- [helm-diff](https://github.com/databus23/helm-diff) (tested with 2.11.0+5)
- [jq](https://github.com/stedolan/jq) (tested with jq-1.5-1-a5b5cbe)
- htpasswd available directly in ubuntus repositories
- [sops](https://github.com/mozilla/sops) (tested with 3.5.0)
- [s3cmd](https://s3tools.org/s3cmd) available directly in ubuntus repositories (tested with 2.0.1)

Installs Ansible and the requirements using the playbook get-requirements.yaml
```
sudo apt-get install ansible=2.5.1+dfsg-1ubuntu0.1 -y && ansible-playbook --connection=local --inventory=127.0.0.1 --limit 127.0.0.1 get-requirements.yaml
```

## Quick setup of a new environment

In order to setup a new Compliant Kubernetes cluster you will need to do the following.

1. Decide on a name for this environment, the cloud provider to use and set
   them as environment variables:

```bash
export CK8S_CLOUD_PROVIDER=[exoscale|safespring]
export CK8S_ENVIRONMENT_NAME=my-ck8s-cluster
# For encrypting config secrets using SOPS
export SOPS_PGP_FP=[PGP fingerprint]
# For setting the Terraform remote workspace execution mode to local
export TF_TOKEN=[Terraform token]
```

2. Then set the path to where the ck8s configuration should be stored:

```bash
export CK8S_CONFIG_PATH=${HOME}/.ck8s/my-ck8s-cluster
```

3. Initialize your environment and configuration:

```bash
./bin/ck8s init
```

4. Edit the configuration files that have been initialized in the configuration
   path.

5. Deploy the cluster:

```bash
./bin/ck8s apply all
```

## Customer access

After the cluster setup has completed RBAC resources, namespaces and a
kubeconfig file (`${CK8S_CONFIG_PATH}/customer/kubeconfig.yaml`) will have
been created for the customer.
You can configure what namespaces should be created and which users that should get access using the following configuration options:

```bash
CUSTOMER_NAMESPACES="demo1 demo2 demo3"
CUSTOMER_ADMIN_USERS="admin1@example.com admin2@example.com"
```

The customer kubeconfig will be configured to use the first namespace by
default.

## DNS

The domain name will be automatically created with the name
`${TF_VAR_dns_prefix}[.ops].a1ck.io` for Exoscale and
`${TF_VAR_dns_prefix}[.ops].elastisys.se` for Safespring.
In Exoscale we use Exoscale's own DNS features while for Safespring we use AWS.

For Safespring the domain can be changed by setting the Terraform variable
`aws_dns_zone_id` to an id of another hosted zone in AWS Route 53.


## Setting up Google as identity provider for dex.

1. Go to the [Google console](https://console.cloud.google.com/) and create a project.

2. Go to the [Oauth consent screen](https://console.cloud.google.com/apis/credentials/consent) and name the application with the same name as the project of your google cloud project add the top level domain e.g. `elastisys.se` to Authorized domains.

3. Go to [Credentials](https://console.cloud.google.com/apis/credentials) and press `Create credentials` and select `OAuth client ID`.
Select `web application` and give it a name and add the URL to dex in the `Authorized Javascript origins` field, e.g. `dex.demo.elastisys.se`.
Add `<dex url>/callback` to Authorized redirect URIs field, e.g. `dex.demo.elastisys.se/callback`.

4. Configure the options `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

## OpenID Connect with kubectl

For using OpenID Connect with kubectl, see
[kubelogin/README.md](kubelogin/README.md).

## OpenID Connect with Harbor

When using Harbor as a reqistry and authenticating with OIDC docker need to be logged
in to that user. For more information how to use it see
[Using OIDC from the Docker or Helm CLI](https://github.com/goharbor/harbor/blob/master/docs/1.10/administration/configure-authentication/oidc-auth.md#using-oidc-from-the-docker-or-helm-cli)

## Adding additional configuration

To add or override the default configuration that is used for all the helm charts that are installed through helmfile, one can set the environement variable `CK8S_ADDITIONAL_VALUES` that should point to a path containing the `{release-name-to-add-or-override}.yaml` files.

## Issues and limitations

### [Exoscale] EIP not reachable from loadbalancer pool

Currently there is an issue where instances, that have been added to the EIP
loadbalancer pool (i.e. when they are no longer seen as unhealthy by the
healthchecks), can't reach the EIP.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030138

### [Exoscale] EIP cleanup sometimes fail

Sometimes EIPs are not possible to delete due to still being seen as having
attached instances.
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030112

### RancherOS multiple interfaces cloud-init issue

Currently cloud-init in RancherOS does not correctly handle when running with multiple network interfaces e.g. `eth0` and `eth1` - (privnet).
See: https://portal.exoscale.com/u/a1di-security-elastisys-dev/tickets/1030849

### Unable to change default password for Elasticsearch user

As of yet it is not possible to change the default password of the **elastic** user that the elasticsearch operator creates.
See https://github.com/elastic/cloud-on-k8s/issues/967

### SOPS exec-[file|env] subcommands does not propagate exit code

SOPS is used to encrypt and decrypt secrets in the CK8S configuration.
`sops exec-[file|env] [secret-file] [command]` is used to temporarily decrypt
secrets and make them available when running a command. However, as of writing,
in the latest stable version this method does not propagate the exit code to
the caller which prevents them from being caught and be handled properly.

To work around this issue, install SOPS from the development branch where a fix
has been commited.
See: https://github.com/mozilla/sops/issues/626
