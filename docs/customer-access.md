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

Log in to the services using the same identity provider you specified earlier as part of the environment setup (e.g. Google or LDAP) unless otherwise noted.

### Service endpoints

- **Kubernetes Dashboard** URL: https://dashboard.CK8S_DOMAIN
- **Kibana** URL: https://kibana.CK8S_DOMAIN
  Log in using a temporary password that you can change later.
- **Harbor** URL: https://harbor.CK8S_DOMAIN
- **Grafana** URL: https://grafana.CK8S_DOMAIN
- **Prometheus** URL: https://prometheus.CK8S_DOMAIN

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

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: custom-jar-monitor
  namespace: test
  labels:
    scrape: "true"
spec:
  selector:
    matchLabels:
      name: my-application
  endpoints:
  - port: metrics-port
```

If your application doesn't already publish metrics in a suitable way for Prometheus to scrape, you may need to use an exporter of some kind.
For example, the [JMX exporter](https://github.com/prometheus/jmx_exporter) exoses JMX metrics from Java applications.

#### Configure Prometheus

The default Prometheus instance that comes with Compliant Kubernetes is in the namespace that is default for your kubeconfig context.
By default it will detect ServiceMonitors in all namespaces and include metrics from them if they have the label `scrape: "true"`.
You can edit the Prometheus instance using this command:

```
kubectl edit prometheuses prometheus
```

Note that if you do not filter the ServiceMonitors in any way, you may end up scraping metrics from some system resources.
To keep the number of metrics (and the storage capacity they require) down, we recommend that you keep the default `serviceMonitorSelector` setting.

#### Prometheus alerts

Prometheus can send out alerts based on the collected metrics.
It can also combine or manipulate the raw data to get more useful, high level metrics.
This is done by providing Prometheus with configuration in the form of CustomResources named [PrometheusRules](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusrule).
There are two types of PrometheusRules: [recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) and [alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/).
Here is an example:

```yaml
# See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusrule
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example
  labels:
    app: prometheus
spec:
  groups:
  - name: example
    rules:
    - alert: ExampleApplicationMemoryHigh
      annotations:
        message: The example application is using a lot of memory!
      # Fire the alert when this expression evaluates to true.
      expr: jvm_memory_bytes_used{area="heap",service="custom-jar-service"} > 20000000
      for: 1m
      labels:
        severity: example
```

Note that Prometheus picks up these rules based on the `ruleSelector`, by default set to match the labels `app: prometheus`.

#### Federation

For redundancy, the metrics collected by this Prometheus instance are also federated to a separate Prometheus instance with a more durable storage backend.
This is possible only because the default Prometheus instance is exposed using an Ingress, as you can see by running `kubectl get ingress`.
The Ingress is protected with basic authentication.
If you remove or change this Ingress or the authentication credentials you risk loosing metrics data, but you may do so if you wish.

#### Grafana integration

Grafana has access to the redundancy Prometheus and can be used to graph any metrics that are federated.

### Alert using Alertmanager

The Prometheus operator included in Compliant Kubernetes can also handle Alertmanager instances.
A default instance is included as an example (see `kubectl get alertmanagers`).
The [Alertmanager documentation](https://prometheus.io/docs/alerting/alertmanager/) and [Prometheus operator alerting documentation](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md) contains more details on how to configure and use Alertmanager.
Note that alerts are configured through Prometheus, Alertmanager just aggregates and sends out notifications.

You may change or delete the default Alertmanager instance or add a new if you wish.
Here is an example:

```yaml
# See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanager
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: alertmanager
  labels:
    app: alertmanager
spec:
  replicas: 1
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
```

Alertmanager is configured using a [configuration file](https://prometheus.io/docs/alerting/configuration/).
Here is an example configuration file for Alertmanager:

```yaml
# Note: Alertmanager instances require the secret resource naming to follow
# the format alertmanager-{ALERTMANAGER_NAME}.
# This config should be stored in a secret with a proper name to be picked
# up by your alertmanager instance. The name of the file in the secret
# must be `alertmanager.yaml`.
#
# See  the following URL for more details on how to configure alertmanager
# https://prometheus.io/docs/alerting/configuration/
global:
  resolve_timeout: 5m
route:
  group_by: ['job']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  # Default receiver
  receiver: slack
  # Specify other receivers depending on match
  routes:
  - match:
      # Send a specific alert to another receiver.
      alertname: bad-alert
    receiver: 'null'
receivers:
- name: 'null'
- name: slack
  slack_configs:
  # Note: the channel here does not apply if the webhook URL is for a specific channel
  - channel: notifications
    # Webhook URL for slack, see https://api.slack.com/apps/
    api_url: https://alertmanagerwebhook.example.com
    # Do you want only alerts firing or also alerts resolved?
    send_resolved: true
    # Alertmanager templating: https://prometheus.io/docs/alerting/notifications/
    text: "You have an alert! {{ .CommonAnnotations.summary }}"
```

To configure the Alertmanager instance, store the file as `alertmanager.yaml` and create a Secret from it named `alertmanager-{ALERTMANAGER_NAME}`, where `{ALERTMANAGER_NAME}` is the name of the Alertmanager instance.
Use kubectl to create the secret like this: `kubectl create secret generic alertmanager-{ALERTMANAGER_NAME} --from-file=alertmanager.yaml`.
Note that it is important that the file is named `alertmanager.yaml` and that the Secret is named according to the instructions for Alertmanager to pick it up.

#### Alerts from Grafana

Grafana can be configured to send alerts to Alertmanager.
For this to work, the Alertmanager instance must be exposed for example using an Ingress.

Configure Grafana by going to *Alerting > Notification channels* and adding a new channel.
Pick *Prometheus Alertmanager* as Type and enter the URL of your exposed Alertmanager instance.

*Hint:* You can configure the Alertmanager Ingress with basic authentication to protect it.
If you do this, remember to add the username and password to the URL you configure in Grafana, like this: `https://username:password@alertmanager.example.com`.
Note that the certificate used for TLS will need to be trusted by Grafana for this to work, so self-signed certificates will not work.

### Persistent storage

PersistentVolumes are supported with a default StorageClass, either `nfs-client` or `cinder-storage`, depending on cloud provider.
As the names suggests, this storage is backed by an NFS server or the OpenStack Cinder provider.
In cases where this is not enough, contact Elastisys for other options, including high performance Node local storage.

### Other services

Falco and Dex are currently not configurable directly.
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
