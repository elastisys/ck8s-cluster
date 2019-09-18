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

All services are available on a domain relative to the workload environment.
If the workload cluster has the domain https://company-1.compliantk8s.com you will for example be able to access the system cluster dashboard at https://dashboard.company-1-system.compliantk8s.com.
In this document, the placeholder `ECK_WC_DOMAIN` will be used to represent the workload domain and `ECK_SC_DOMAIN` the service domain.
If you want to replace `ECK_WC_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/ECK_WC_DOMAIN/customer-1.compliantk8s.com/g' docs/operator-access.md
```

Log in to the services using your A1 AAA or Google credentials.

### Service endpoints

- **Kubernetes workload cluster Dashboard** URL: https://dashboard.ECK_WC_DOMAIN
- **Kubernetes service cluster Dashboard** URL: https://dashboard.ECK_SC_DOMAIN
- **Kibana** URL: https://kibana.ECK_WC_DOMAIN
- **Harbor** URL: https://harbor.ECK_WC_DOMAIN
- **Grafana** URL: https://grafana.ECK_SC_DOMAIN
- **Prometheus** URL: TODO
- **Alertmanager** URL: TODO

### Other services

Falco, Fluentd, Prometheus and Dex are currently configured directly through the helm charts only.
