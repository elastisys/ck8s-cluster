# Operator access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services operators can access.

## Kubernetes API

You can access the Kubernetes API by using the kubeconfig files produced by RKE during installation.
There is one for the workload cluster and one for the service cluster.

**TODO:** Determine how these files should be stored and distributed among operators.

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
