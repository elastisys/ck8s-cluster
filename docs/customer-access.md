# Customer access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services customers can access.

## Kubernetes API

You can access the Kubernetes API by using [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [kubelogin](https://github.com/int128/kubelogin).
Install both tools (`kubectl` first and then `kubelogin`).
Next, you will need to point `kubectl` to the `kubeconfig.yaml` file you should have received when your environment was created.
You can do this either by moving and renaming the `kubeconfig.yaml` to `~/.kube/config`, as this is the default location, or by setting the environment variable `KUBECONFIG` to the path of the `kubeconfig.yaml` file.

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
In this document, the placeholder `CK8S_DOMAIN` will be used to represent the cluster domain.
If you want to replace `CK8S_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/CK8S_DOMAIN/customer-1.compliantk8s.com/g' docs/customer-access.md
```

Log in to the services using your A1 AAA or Google credentials.

### Service endpoints

- **Kubernetes Dashboard** URL: https://dashboard.CK8S_DOMAIN
- **Kibana** URL: https://kibana.CK8S_DOMAIN
- **Harbor** URL: https://harbor.CK8S_DOMAIN
- **Grafana** URL: https://grafana.CK8S_DOMAIN
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

### Other services

Falco, Fluentd and Dex are currently not configurable directly.
Access to Alertmanager and Prometheus is not yet available.
If you require changes/access to these services, please contact us.

TODO:

- Falco: Customers should be able to set up notifications and maybe also change/add rules to falco.
- Dex: Should customers be able to configure this? Should they be able to add their own IDPs?
- Fluentd/Elasticsearch/Kibana: Customers may need to parse application logs in specific ways.
- Prometheus: Customers probably want to collect (custom) metrics from their applications. Should they set up their own prometheus for this or use the built in? How?
- Alertmanager: Customers may want to define their own alerts and configure where notifications go.
