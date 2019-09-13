# Customer access

> **DRAFT warning**
This document is just a draft.
It may not accurately describe the current state of affairs or even how things will work in the future.

This document describes how and what services customers can access.

## Kubernetes API

You can access the Kubernetes API by using [kubelogin](https://github.com/int128/kubelogin).
Simply install the plugin and then create a kubeconfig context for your cluster.

You can use the snippet below to set up your kubeconfig file.
Start by setting the four environment variables (`ECK_WC_DOMAIN`, `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID` and `OIDC_CLIENT_SECRET`).
The snippet creates an entry in your kubeconfig file with a cluster named `compliantk8s`, a user named `developer` and a context named `developer@compliantk8s`.
Feel free to change these names if you like.

```
ECK_WC_DOMAIN=<your-eck-domain-here>
OIDC_ISSUER_URL=<your-issuer-url-here>
OIDC_CLIENT_ID=<your-client-id-here>
OIDC_CLIENT_SECRET=<your-client-secret-here>

kubectl config set-cluster compliantk8s --server=https://${ECK_WC_DOMAIN}:6443
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

You are now ready to log in and start using the Kubernetes API.
The kubelogin plugin will ask you to log in using your browser the first time try to access the API and again when your token expires.
For example:
```
$ kubectl get nodes
Open http://localhost:8000 for authentication
You got a valid token until 2019-08-24 16:15:50 +0200 CEST
```

## Available Services

All services are available on a domain relative to your environment.
If your cluster has the domain https://company-1.compliantk8s.com you will for example be able to access the dashboard at https://dashboard.company-1.compliantk8s.com.
In this document, the placeholder `ECK_WC_DOMAIN` will be used to represent the cluster domain.
If you want to replace `ECK_WC_DOMAIN` with your actual domain in this document, do the following:

```shell
sed 's/ECK_WC_DOMAIN/customer-1.compliantk8s.com/g' docs/customer-access.md
```

Log in to the services using your A1 AAA or Google credentials.

### Service endpoints

- **Kubernetes Dashboard** URL: https://dashboard.ECK_WC_DOMAIN
- **Kibana** URL: https://kibana.ECK_WC_DOMAIN
- **Harbor** URL: https://harbor.ECK_WC_DOMAIN
- **Grafana** URL: https://grafana.ECK_WC_DOMAIN
- **Prometheus** URL: TODO
- **Alertmanager** URL: TODO

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
