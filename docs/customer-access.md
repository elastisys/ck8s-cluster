# Customer access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services customers can access.

## Kubernetes API

<<<<<<< HEAD
You can access the Kubernetes API by using [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [kubelogin](https://github.com/int128/kubelogin).
Install both tools (`kubectl` first and then `kubelogin`).
Next, you will need to point `kubectl` to the `kubeconfig.yaml` file you should have received when your environment was created.
You can do this either by moving and renaming the `kubeconfig.yaml` to `~/.kube/config`, as this is the default location, or by setting the environment variable `KUBECONFIG` to the path of the `kubeconfig.yaml` file.
=======
You can access the Kubernetes API by using [kubelogin](https://github.com/int128/kubelogin).
Simply install the plugin and then create a kubeconfig context for your cluster.

You can use the snippet below to set up your kubeconfig file.
Start by setting the four environment variables (`ECK_BASE_DOMAIN`, `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID` and `OIDC_CLIENT_SECRET`).
The snippet creates an entry in your kubeconfig file with a cluster named `compliantk8s`, a user named `developer` and a context named `developer@compliantk8s`.
Feel free to change these names if you like.

```
ECK_BASE_DOMAIN=<your-eck-domain-here>
OIDC_ISSUER_URL=<your-issuer-url-here>
OIDC_CLIENT_ID=<your-client-id-here>
OIDC_CLIENT_SECRET=<your-client-secret-here>

kubectl config set-cluster compliantk8s --server=https://${ECK_BASE_DOMAIN}:6443
kubectl config set-credentials developer --exec-command=kubelogin \
  --exec-api-version=client.authentication.k8s.io/v1beta \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=${OIDC_ISSUER_URL} \
  --exec-arg=--oidc-client-id=${OIDC_CLIENT_ID} \
  --exec-arg=--oidc-client-secret=${OIDC_CLIENT_SECRET} \
  --exec-arg=--oidc-extra-scope=email
kubectl config set-context developer@compliantk8s --user developer --cluster=compliantk8s
kubectl config use-context developer@compliantk8s
```
>>>>>>> replaced ECK_WC_DOMAIN and ECK_SC_DOMAIN with ECK_BASE_DOMAIN and ECK_OPS_DOMAIN

You are now ready to log in and start using the Kubernetes API.
The kubelogin plugin will ask you to log in using your browser the first time try to access the API and again when your token expires.
For example:
```
$ kubectl cluster-info
Open http://localhost:8000 for authentication
You got a valid token until 2019-08-24 16:15:50 +0200 CEST
```

You should log in using the same identity provider you specified earlier as part of the environment setup (e.g. Google or LDAP).

## Available Services

All services are available on a domain relative to your environment.
If your cluster has the domain https://company-1.compliantk8s.com you will for example be able to access the dashboard at https://dashboard.company-1.compliantk8s.com.
<<<<<<< HEAD
In this document, the placeholder `CK8S_DOMAIN` will be used to represent the cluster domain.
If you want to replace `CK8S_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/CK8S_DOMAIN/customer-1.compliantk8s.com/g' docs/customer-access.md
=======
In this document, the placeholder `ECK_BASE_DOMAIN` will be used to represent the cluster domain.
If you want to replace `ECK_BASE_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/ECK_BASE_DOMAIN/customer-1.compliantk8s.com/g' docs/customer-access.md
>>>>>>> replaced ECK_WC_DOMAIN and ECK_SC_DOMAIN with ECK_BASE_DOMAIN and ECK_OPS_DOMAIN
```

Log in to the services using the same identity provider you specified earlier as part of the environment setup (e.g. Google or LDAP) unless otherwise noted.

### Service endpoints

<<<<<<< HEAD
- **Kubernetes Dashboard** URL: https://dashboard.CK8S_DOMAIN
- **Kibana** URL: https://kibana.CK8S_DOMAIN
  Log in using a temporary password that you can change later.
- **Harbor** URL: https://harbor.CK8S_DOMAIN
- **Grafana** URL: https://grafana.CK8S_DOMAIN
=======
- **Kubernetes Dashboard** URL: https://dashboard.ECK_BASE_DOMAIN
- **Kibana** URL: https://kibana.ECK_BASE_DOMAIN
- **Harbor** URL: https://harbor.ECK_BASE_DOMAIN
- **Grafana** URL: https://grafana.ECK_BASE_DOMAIN
>>>>>>> replaced ECK_WC_DOMAIN and ECK_SC_DOMAIN with ECK_BASE_DOMAIN and ECK_OPS_DOMAIN
- **Prometheus** URL: TODO
- **Alertmanager** URL: TODO

### Fluentd

Fluentd gathers logs from all pods in the cluster and forwards them to Elasticsearch.
It also adds metadata to the logs (e.g. namespace and pod where they come from).
In addition to this, you may want to configure specific rules for how to parse the logs and process the messages in some way before they end up in Elasticsearch.

To add extra configuration to fluentd you can edit the configmap `fluentd-extra-config` in the `fluentd` namespace.
This config will be included together with the default configuration for where to find logs and where to send them.
Since fluentd does not actively watch the configmap for changes, you will need to restart it by deleting the fluentd pods.
This will cause new pods to start and read in the configuration.

You can edit the configmap using this command:
```
kubectl -n fluentd edit configmap fluentd-extra-config
```

Restart fluentd by killing the pods:
```
kubectl -n fluentd delete pods -l app.kubernetes.io/instance=fluentd
```

### Ingress controller

The [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) is included and can be used to expose applications running in the cluster by creating [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/).

### Cert-manager

Cert-manager is included and can be used by creating one or more [Issuers](https://docs.cert-manager.io/en/latest/tasks/issuers/index.html).
To get a certificate you will need to either create a [Certificate resource](https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/index.html) or add the proper [annotations to an Ingress](https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/ingress-shim.html) in your cluster.

### Backup

Kubernetes resources with the label `velero: backup` will be backed up daily.
Persistent volumes will be backed up if they are tied to a Pod with the previously mentioned label and the annotation `backup.velero.io/backup-volumes=<volume1>,<volume2>,...`.

### Monitoring with Prometheus

Compliant Kubernetes includes the Prometheus operator and a Prometheus instance, which can be used for monitoring applications in the cluster.
You can use a Custom Resource called [ServiceMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md#servicemonitor) to define what endpoints to scrape metrics from.
The API reference for ServiceMonitors is available [here](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitor).
A simple example is provided here below:

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: customer-jar-monitor
  namespace: test
  labels:
    release: prometheus-operator
spec:
  selector:
    matchLabels:
      name: my-application
  endpoints:
  - port: metrics-port
```

If your application doesn't already publish metrics in a suitable way for Prometheus to scrape, you may need to use an exporter of some kind.
For example, the [JMX exporter](https://github.com/prometheus/jmx_exporter) exoses JMX metrics from Java applications.

### Persistent storage

PersistentVolumes are supported with a default StorageClass `nfs-client`.
As the name suggests, this storage is backed by an NFS server.
In cases where this is not enough, contact Elastisys for other options, including high performance Node local storage.

### Other services

Falco, Fluentd and Dex are currently not configurable directly.
Access to Alertmanager and Prometheus is not yet available.
If you require changes/access to these services, please contact us.

## Known issues and limitations

- [Load balancer Services](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) are currently not supported.

### Limited privileges

To keep the Compliant Kubernetes platform secure and to be able to take responsibility for as much as possible of it, users will not have the normal `cluster-admin` privileges.
Instead, users are given `admin` privileges in specific Namespaces with access to a restrictive PodSecurityPolicy.
This means that users will not be able to control resources at the cluster level (e.g. ClusterRoles) or run containers with the `root` user.
Access to Nodes is also restricted (e.g. it is not allowed to mount host paths to a Pod).

## Contact support

If you are having issues with your cluster or questions about how things work, reach out to Elastisys support team at support@elastisys.com!

## TODO

- Falco: Customers should be able to set up notifications and maybe also change/add rules to falco.
- Fluentd/Elasticsearch/Kibana: Customers may need to parse application logs in specific ways.
- Alertmanager: Customers may want to define their own alerts and configure where notifications go.
