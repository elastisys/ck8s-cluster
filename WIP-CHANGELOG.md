### Fixed
- Tests respect the `ENABLE_FALCO` and `ENABLE_FALCO_ALERTS` configuration

### Breaking changes
- Adding anti-affinity to nodes in openstack will force them to be recreated by terraform. This will then break the kubernetes clusters.

### Release notes
- No migration path is available for adding anti-affinity in openstack.

### Added
- The master and worker VMs in openstack can now, optionally, have anti-affinity or soft anti-affinity. Soft anti-affinity is not available in Safespring.
- Documentation describing which api extensions that are used by ck8s.

### Fixed
- Added quotes to handle special characters (e.g for password etc) in cloud.conf.
- `ck8s dry-run` now takes config into account when determining which helmfile charts to diff.

### Removed
- Unused elasticsearch output plugin parameters from fluentd.
