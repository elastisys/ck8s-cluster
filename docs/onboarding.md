# On-boarding

This document describes the on-boarding process and the information needed in each step.

## Step 1 - Decide on environment parameters

*Note:* This step will be completely manual at first.
We (Elastisys) need to ask the customer about the details of the environment (e.g identity provider).
Later on, this could be automated and turned into an online form to fill in.

- What **cloud provider** should this environment use?
  For example Safespring or Exoscale.
- What **name** and **domain** should the environment have?
  For example, name `foo` with domain `foo.compliantk8s.com`.
- What **identity provider** should be used for logging in?
  We need some specific information to [configure dex](https://github.com/dexidp/dex#connectors).
  For example, if using Google as identity provider, we will need to know if we should restrict authentication to a specific domain.
  We will also need a list of at least one account that should get admin access.
  These users will be able to configure permissions for other users.
- What **optional services** should be deployed (e.g. Harbor and OPA)?
- What **namespaces** should be created for the customer?
- How would you like to be **notified** about upgrades, maintenance and similar?

## Step 2 - Deploy environment

*Note:* This step should not require any additional input from the customer.
Everything necessary should have been specified during step 1.
It is important to let the customer know what to expect during this time: How long will it take? What will happen next?

In this step we (Elastisys) create infrastructure, configuration, credentials, etc. and install Kubernetes as well as the managed services.

### Manual steps

#### Kibana

Give customer access to Kibana and Elasticsearch:

1. Log in to Kibana as the elastic user
2. Go to *Management > Roles*
3. Create a role called `kubernetes-log-reader` with `read` privilege for indices `kubernetes-*` and `kubeaudit-*`.
4. Create a role called `backup-exporter` with cluster privileges `cluster:monitor/state` and `cluster:monitor/health`; index privileges `monitor` for `*` and `read` for `kubernetes-*` and `kubeaudit-*`.
5. Go to *Management > Users*
6. Create a user for the customer with roles `kibana_user`, `kubernetes-log-reader` and `backup-exporter`.
7. Give credentials to the customer (and encourage them to change the password).

## Step 3 - Handover

*Note:* This step will be completely manual at first, including a hands-on walk through of the system and services.
Once we learn more about what customers need to get started, we should turn this into documentation that can be published openly for all customers to use.
This step can also include fine-tuning of the environment initially (e.g. give the customer more privileges).
However, this should preferably be done during steps 1 and 2 if possible.

We (Elastisys) send details on the new environment to the customer.
This includes any needed credentials and access endpoints as well as information about procedures (upgrades, maintenance, etc.).
We should also include some getting started instructions and help the customer to get started with the environment.

After this step the customer should

- know how to access the Kubernetes API
- know how to access the Kubernetes dasboard
- know how to access Kibana
- know how to access Grafana
- know how to access Harbor
- know how to access and configure Alertmanager
- know how to use the built in ingress-controller
- know how to use cert-manager to generate certificates
- know how to configure Prometheus to scrape application metrics
- know how to configure Fluentd to correctly parse application logs
- know how to configure backups
- know how to contact us in case of problems
- know about known issues with the platform
- know about common processes that are part of the managed platform

See [customer-access.md](customer-access.md) and [processes.md](processes.md).
