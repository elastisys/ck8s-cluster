# Operator access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services operators can access.

## Kubernetes API

You can access the Kubernetes API by using the kubeconfig files produced by RKE during installation.
There is one for the customer cluster and one for the system services cluster.

**TODO:** Determine how these files should be stored and distributed among operators.

## Helm and tiller

Helm and tiller is configured to use TLS.
This means that you need to set up a specific environment with certificates in order to access tiller.
The certificates used are created during installation and are by default stored in the `certs` folder in the root of the repository.

Set up environment variables for accessing the secured tiller like this (note that `kubectl` should already be configured for the cluster you want to access before you do this):
```shell
# Namespace, cert dir and client as arguments.
# Switch system-services to customer to access the customer cluster.
source scripts/helm-env.sh kube-system certs/system-services/certs admin1
# Make sure you can access tiller
helm version
# Should give output similar to this:
# Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
# Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```

You are now ready use helm with this cluster.

**TODO:** Determine how the certificates should be stored and distributed among operators.

## Available Services

All services are available on a domain relative to the customer environment.
If the customer cluster has the domain https://company-1.compliantk8s.com you will for example be able to access the system cluster dashboard at https://dashboard.company-1-system.compliantk8s.com.
In this document, the placeholder `ECK_DOMAIN` will be used to represent the customer domain and `ECK_SYSTEM_DOMAIN` the system domain.
If you want to replace `ECK_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/ECK_DOMAIN/customer-1.compliantk8s.com/g' docs/operator-access.md
```

Log in to the services using your A1 AAA or Google credentials.

### Service endpoints

- **Kubernetes customer Dashboard** URL: https://dashboard.ECK_DOMAIN
- **Kubernetes system Dashboard** URL: https://dashboard.ECK_SYSTEM_DOMAIN
- **Kibana** URL: https://kibana.ECK_DOMAIN
- **Harbor** URL: https://harbor.ECK_DOMAIN
- **Grafana customer** URL: https://grafana.ECK_DOMAIN
- **Grafana system** URL: https://grafana.ECK_SYSTEM_DOMAIN
- **Prometheus** URL: TODO
- **Alertmanager** URL: TODO

### Other services

Falco, Fluentd, Prometheus and Dex are currently configured directly through the helm charts only.
