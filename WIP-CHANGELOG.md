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

### Fixed

- Index templates in elasticsearch not selecting the correct ilm policies.
- New index patterns in Kibana that matches new inices.
- Harbor init not completing in time for tests.

### Removed

- Documentation regarding operations.
- Ansible parts that are no longer needed with BaseOS, such as installing docker
- Old script for generating ansible inventory from infra.json
- Support for attaching extra disks to Safespring and Citycloud workers
- Rancher Kubernetes Engine (RKE)

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
