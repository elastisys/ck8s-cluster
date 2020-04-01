### Breaking changes
- Terraform now uses new a required config file for configuring the remote backend.

### Release notes
- To migrate your CK8S config to use the new backend config file run `./migration/v0.2.x-v0.3.0/migrate-tf-config.bash`

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

### Fixed

- Index templates in elasticsearch not selecting the correct ilm policies.
- New index patterns in Kibana that matches new inices.
- Harbor init not completing in time for tests.
- Added missing parameter to velero default volumesnapshotlocation
- Alertmanager not getting installed in the WC even when 
`ENABLE_CUSTOMER_ALERTMANAGER` is set to true
- Falco getting installed even if `ENABLE_FALCO=false`

### Removed

- Documentation regarding operations.
- Ansible parts that are no longer needed with BaseOS, such as installing docker
- Old script for generating ansible inventory from infra.json
- Support for attaching extra disks to Safespring and Citycloud workers
- Rancher Kubernetes Engine (RKE)
- Logs from the kubelet are no longer collected and forwarded to Elasticsearch.

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
