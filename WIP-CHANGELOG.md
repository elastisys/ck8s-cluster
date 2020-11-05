
### Breaking changes

- DNS records must now be managed manually. For safespring and citycloud you must remove the terraform state for the DNS records before upgrading to this version.

### Release notes

- The new OIDC config variables can be added with a migration script for v0.8.0.

### Added

- Initial Azure support.
- Added new variables for the Kubernetes api server OIDC config.
- `extra_tags` support for AWS.
- Check if cloud provider is AWS so node name tests can be executed

### Removed

- Removed all DNS creation.
- Removed the `dns_prefix` config variable.
