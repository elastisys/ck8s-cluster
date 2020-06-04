# Compliant Kubernetes changelog
<!-- BEGIN TOC -->
- [v0.3.0](#v030---2020-06-04)
- [v0.2.4](#v024---2020-04-29)
- [v0.2.3](#v023---2020-04-17)
- [v0.2.2](#v022---2020-04-09)
- [v0.2.1](#v021---2020-04-03)
- [v0.2.0](#v020---2020-03-26)
- [v0.1.0](#v010---2020-03-06)
<!-- END TOC -->

-------------------------------------------------
## v0.3.0 - 2020-06-04

### Breaking changes
- Kubeadm replaces RKE as the Kubernetes cluster lifecycle tool.
- Terraform now uses new a required config file for configuring the remote backend.
- Terraform for safespring and citycloud have been restructured with new modules.
- Upgraded cert-manager to v0.14.1 which breaks the user facing API.
  Please look at the [upgrade guide](https://cert-manager.io/docs/installation/upgrading/)
  for steps that might be needed for services running in CK8S.
- Upgraded the BaseOS image on Exoscale, Citycloud, Safespring and AWS to contain the
  Kubernetes control plane container images. This will require full
  reinstallation of Kubernetes and apps.
- Exoscale now uses a stable EIP as public endpoint for the control plane.
- Safespring now uses a HAProxy as public endpoint for the control plane.
- Citycloud now uses an Octavia LB and floating IP as endpoint for the control plane.
- Api change: `api_server_whitelist` now required in `config.tfvars`
- Api change: `public_ingress_cidr_whitelist` is now required to be a list in `config.tfvars`

### Release notes
- It's not possible to migrate from RKE to Kubeadm without creating a new cluster.
- To migrate your CK8S config to use the new backend config file run `./migration/v0.2.x-v0.3.0/migrate-tf-config.bash`
- No migration script is available for the terraform changes to safespring and citycloud. Manual migration might be possible.
- No migration script is available for cert-manager. A new cluster is required.
- No migration path is available for the control plane public endpoint change on Exoscale, Safespring and Citycloud. The clusters must be recreated.
- To apply grafana dashboard improvements to existing clusters run `./migration/v0.2.x-v0.3.0/migrate-grafana-dashboards.bash`
- The NFS servers need to be rebooted to apply the removal of the whitelisting
  after the change has been applied.
- No migration path as available for adding support for LoadBalancers on Citycloud. A new cluster is required.

### Added

- Allow disabling the `ck8sdash` deployment
- NGINX IP whitelist support
- Enable setting local `externalTrafficPolicy` in `nginx-ingress`
- Support to create a cluster on Citycloud
- Ability to add and remove PGP keys from SOPS config through the CLI:
  `ck8s team add-pgp [fp]` and `ck8s team remove-pgp [fp]`
- Label owner=operator to namespaces
- Add command `ck8s ops kubectl` for emergency situations when normal kubectl
  access is not possible.
- Add command `ck8s ops helmfile` for emergency situations when a partial
  Helmfile run is necessary.
- Add command `ck8s ssh` that makes it possible to SSH to the various CK8S
  machines.
- Add command `ck8s s3cmd` that makes it possible to run s3cmd with the
  encrypted s3cmd config file.
- Auto-completion for the cli
- S3 support for the AWS cloud provider
- Ansible inventory generated directly in terraform for Exoscale, Safespring, and Citycloud
- `metrics-server` is installed on kubeadm-installed clusters as well.
- AWS: use network load balancer for `nginx-ingress`
- Added AWS support to the `set-execution-mode.sh` script
- AWS: EBS storage class support
- AWS: Additional storage class for sensitive/important data that is
  encrypted and retained
- Support to configure falco alerts for slack and alertmanager.
- Falcosidekick for handling falco outputs.
- EIP for control plane on Exoscale
- Octavia LB for control plane on Citycloud.
- Support for HA control plane on Exoscale, Safespring and Citycloud.
- End-user roles for Kibana are now created automatically during deployment.
- CRDs, with the exemption of project calico, are now vendored in the /crds folder and deployed using ansible during the k8s apply step.
- Fluentd-prometheus exporter for SC and WC
- Custom alert chart (based on prometheus-operator alerts) to make it easier to tweak, enable/disable alerts as needed.
- Documentation regarding cluster migration
- Api server whitelisting on all providers
- Pipeline now uses and tests whitelisting
- Documentation regarding licenses used in ck8s
- Ability to set `maxconn` and `server/client timeout` in HAproxy configuration for safespring.
- Citycloud: support Services of type LoadBalancer

### Fixed

- Index templates in elasticsearch not selecting the correct ilm policies.
- New index patterns in Kibana that matches new inices.
- Harbor init not completing in time for tests.
- Added missing parameter to velero default volumesnapshotlocation
- Alertmanager not getting installed in the WC even when
`ENABLE_CUSTOMER_ALERTMANAGER` is set to true
- Falco getting installed even if `ENABLE_FALCO=false`
- Kube-proxy metrics endpoint fixed.
- Etcd metrics endpoint fixed.
- Configure-es does not complete within activeDeadlineSeconds
- Ck8s-dash config for datasources now matches the new datasource names

### Removed

- Documentation regarding operations.
- Ansible parts that are no longer needed with BaseOS, such as installing docker
- Old script for generating ansible inventory from infra.json
- Support for attaching extra disks to Safespring and Citycloud workers
- Rancher Kubernetes Engine (RKE)
- Logs from the kubelet are no longer collected and forwarded to Elasticsearch.
- Prometheus-operator built-in alerts

### Changed

- `SOPS_PGP_FP` is deprecated in favor of using a
  [SOPS config file](https://github.com/mozilla/sops/blob/master/README.rst#using-sops-yaml-conf-to-select-kms-pgp-for-new-files).
  Use `CK8S_PGP_UID` or `CK8S_PGP_FP` when initializing the CK8S config.
- Exoscale EIP is reintroduced as loadbalancer for the nginx ingress
  controller. This also means that the DNS records now points to the EIP IP
  address instead of every worker.
- Using BaseOS as VM image instead of plain ubuntu for all k8s nodes on Exoscale, Safespring, and Citycloud.
- Switch from RKE to kubeadm for k8s cluster management
- Switch CNI from Canal to Calico
- Using Neutron instead of Nova network for security rules in Safespring and Citycloud.
- Clean up volumes also in the workload cluster for Safespring and Citycloud
- Control plane logs (not audit logs) now go to the `kubernetes` index instead of `kubecomponents`.
- AWS: The DNS terraform module is now to be used standalone instead of by the infrastructure module.
- Storage class for Elasticsearch Nodes is now configurable. Local storage is now used by default in the Exoscale environment. It is provisioned by [sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner).
- Upgraded helm to v3
- Terraform backend now configured from a seperated file `backend_config.hcl`
- Ignore `falco syscall event dropped` messages. These messages were spamming and thus being
  ignored anyway. (Should be enabled once falco reaches 1.0.0)
- Upgraded falco helm chart to v1.1.6 (falco v0.22.1)
- Falco now also runs on masters.
- Falco now alerts on ssh to nodes.
- Safespring and citycloud now uses common openstack modules in terraform.
- Cert-manager upgraded to version 0.14.1
- BaseOS image on Exoscale, Citycloud, Safespring and AWS contains Kubernetes controlplane
  container images.
- Customer admin now has view access to the falco namespace.
- Upgraded prometheus operator to version 8.13.2 and Prometheus to v2.17.2
- Ck8s-dash upgraded to version 0.2.1
- NFS server whitelisting has been removed from Exoscale
- OPA is now managed using Gatekeeper
- By default the OPA policies will be audited in the customer namespaces.
  There is an option to instead deny requests that violate any policy.
- The following three OPA policies are now added:
  * only allowing images from our harbor,
  * requiring networkpolicies for all pods,
  * and requiring resource requests on all pods.
- `public_ingress_cidr_whitelist` is now a list on openstack providers
- Exoscale clusters to now use private network for internal communication

-------------------------------------------------
## v0.2.4 - 2020-04-29

### Release notes

- If you already have upgraded to 0.2.x you might have to manually clean up
  indices with errors as well as re-trigger the configure-es job to apply the
  updates to the index templates.

### Fixed

- Index templates in elasticsearch not selecting the correct ilm policies.
- Harbor init not completing in time for tests.


-------------------------------------------------
## v0.2.3 - 2020-04-17

### Added

- Option to disable namespace creation in customer-rbac.
- Auto create capability for system monitoring indices in elasticsearch.

-------------------------------------------------
## v0.2.2 - 2020-04-09

### Added

- Option to disable InfluxDB size-based retention.

-------------------------------------------------
## v0.2.1 - 2020-04-03

### Added

- Elasticsearch index creation in `configure-es` job.
-------------------------------------------------
## v0.2.0 - 2020-03-26

### Added

- Customer RBAC for managing ServiceMonitors, PodMonitors and PrometheusRules
- Initial version of configuration and command facade.
- SOPS secrets management.
- OIDC support for harbor.
- Node local DNS cache
- Backup chart for harbor using a cronjob.

### Changed

- Influxdb is now deployed from a fork of the stable/influxdb chart, instead of using Kustomize to modify the original.
- Pipeline only tests Harbor if `ENABLE_HARBOR` is set to true.
- Refactorization of configuration repositories.
- Provided more meaningful context to kubeconfig names

### Removed

- Kustomize is no longer needed and has been removed.
- Vault secrets management.

### Fixed

- Invalid index selection in SLM policy for nightly elasticsearch snapshots.
- `S3COMMAND_CONFIG_FILE` is now used as the config file path for all s3cmd
  executions in `manage-s3-bucket.sh`. Previously the `--abort` flag did not
  use it and instead defaulted to `${HOME}/.s3cfg`.
- Harbor signing issue were notary certificate was invalid.
- Harbor secrets can now be set from environment variables.

-------------------------------------------------
## v0.1.0 - 2020-03-06

## Initial release
First release of Elastisys Compliant Kubernetes
