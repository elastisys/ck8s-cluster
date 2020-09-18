### Breaking changes

- The old Terraform variables configuration (config.tfvars) is no longer
  supported and needs to be updated to the new format (tfvars.json). However,
  once the configuration has been updated it can be applied without any change.
  See: [docs/migration/0.6.0.md#tfvars](docs/migration/0.6.0.md#tfvars)
- PSPs cannot be disabled anymore. The effect has to be achieved by creating a permissive policy.
  After an update to v0.6.0, it is required to edit the manifest for the static apiserver pods to enable the `PodSecurityPolicy` admission plugin.
- The old cluster configuration *(config.sh)* is no longer supported and needs to be updated to the new format *(config.yaml)*.
  However, once the configuration has been updated it can be applied without any change.
  See: [docs/migration/0.6.0.md#config](docs/migration/0.6.0.md#config)
- The old cluster secret configuration *(secrets.env)* is no longer supported and needs to be updated to the new format *(secrets.yaml)*.
  However, once the configuration has been updated it can be applied without any change.
  See: [docs/migration/0.6.0.md#secrets](docs/migration/0.6.0.md#secrets)

### Release notes

- The prod flavor is broken on Exoscale due to the machine disks being too small for the local volumes.
  You may configure smaller volumes than the default to work around this.
- The `ENABLE_PSP` value should be removed from the config, see breaking changes regarding PSPs.
- The static apiserver pod manifests should be edited to enable the `PodSecurityPolicy` admission plugin **after** the upgrade.

### Added

- Added prod flavor for production grade defaults.
- Command to add new machines.
- Support for cloning and replacing nodes but with a different image.

### Fixed

- Bug where tfe provider do not read the configured value in backend_config.hcl
- Bug where folders where not created before uploading crds
- Missing join-cluster Ansible playbook path which caused node replacement and
  cloning to fail.
- The Terraform plan diff check to also include the case where a plan is being
  caused by data sources with depends_on but no actual change occured. This
  currently happens for the Exoscale provider.
- Interactive runs with SSH commands (e.g. kubeadm reset) not working properly
  due to stdin being blocked after the SSH session closed.

### Changed

- Removed some default values to make this ready for open sourcing
- tfvars machines configuration so that name, node type, size and more are all
  grouped into a single object.
- tfvars configuration language from HCL to JSON.
- all commands that previously required node type as an argument no longer do,
  only node name is now needed (e.g. `drain master foo` -> `drain foo`).
- Citycloud: Api server white list is applied to api server loadbalancer now as well as the VMs.
- Increases timeout for api server loadbalancer to 10m
- Removed CRDs. These will be installed from the apps repository instead.
- Reduced local volume size for dev flavor.
- Reduced control plane node sizes on Safespring for dev flavor.
- Configuration files *(config.sh and secrets.env)* changed from *dotenv* format to *yaml*.
