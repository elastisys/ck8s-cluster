# Operator access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services operators can access.

## Kubernetes API

You can access the Kubernetes API by using the kubeconfig files produced by RKE during installation.
There is one for the workload cluster and one for the service cluster.

**TODO:** Determine how these files should be stored and distributed among operators.

## Helm and tiller

Helm and tiller is configured to use TLS.
This means that you need to set up a specific environment with certificates in order to access tiller.
The certificates used are created during installation and are by default stored in the `certs` folder in the root of the repository.

Set up environment variables for accessing the secured tiller like this (note that `kubectl` should already be configured for the cluster you want to access before you do this):
```shell
# Namespace, cert dir and client as arguments.
# Switch service_cluster to workload_cluster to access the customers cluster.
source scripts/helm-env.sh kube-system certs/service_cluster/certs admin1
# Make sure you can access tiller
helm version
# Should give output similar to this:
# Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
# Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```

You are now ready use helm with this cluster.

**TODO:** Determine how the certificates should be stored and distributed among operators.

## Available Services

All services which are opened to the customers will have the endpoint `https://<service>.<customer>.<domain>`. 
For example the dashboard for a customer could have enpoint `https://dashboard.customer.elastisys.se`. 
The placeholder `ECK_BASE_DOMAIN` is used throughout the documentaion and script
for `<customer>.<domain>`. 

All services only available to operators and hosted in the service cluster will have
the endpoint `https://<service>.ops.<customer>.<domain>`. The placeholder `ECK_OPS_DOMAIN`
is used for `ops.<customer>.<domain>`.

If you want to replace `ECK_BASE_DOMAIN` with your actual domain in this document, do the following:

Log in to the services using your A1 AAA or Google credentials.

### Alerting to Slack

Alertmanager can be used to send alerts to slack.
See [example-env.sh](../example-env.sh) for available environment variables for alerting.

Alerts through Slack requires a [slack app](https://api.slack.com/).
The one we are currently using can be found [here](https://api.slack.com/apps/ANJ11SFK3/general?).
You will need to create a [webhook URL](https://api.slack.com/apps/ANJ11SFK3/incoming-webhooks?) for each channel you want to send alerts to.

The alertmanager configuration can be found in [prometheus-operator-sc.yaml.gotmpl](../helmfile/values/prometheus-operator-sc.yaml.gotmpl)

### Customer accessable Service endpoints

- **Kubernetes workload cluster Dashboard** URL: https://dashboard.ECK_BASE_DOMAIN
- **Kibana** URL: https://kibana.ECK_BASE_DOMAIN
- **Harbor** URL: https://harbor.ECK_BASE_DOMAIN
- **Grafana** URL: https://grafana.ECK_BASE_DOMAIN

- **Prometheus** URL: TODO
- **Alertmanager** URL: TODO

### Only operator accessable endpoints

- **Kubernetes service cluster Dashboard** URL: https://dashboard.ECK_OPS_DOMAIN
- **elasticsearch** URL: https://elastic.ECK_OPS_DOMAIN

### Other services

Falco, Fluentd, Prometheus and Dex are currently configured directly through the helm charts only.
