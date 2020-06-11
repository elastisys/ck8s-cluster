### Fixed
- Added quotes to handle special characters (e.g for password etc) in cloud.conf.

### Breaking changes
- Adding anti-affinity to nodes in openstack will force them to be recreated by terraform. This will then break the kubernetes clusters.

### Release notes
- No migration path is available for adding anti-affinity in openstack.

### Added
- The master and worker VMs in openstack can now, optionally, have anti-affinity or soft anti-affinity. Soft anti-affinity is not available in Safespring.

### Removed
- Unused elasticsearch output plugin parameters from fluentd.
