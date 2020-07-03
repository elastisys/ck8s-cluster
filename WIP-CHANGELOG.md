### Changed
- Curator now looks at the index name to determine its age instead of looking at the index creation date
- Nginx-ingress upgraded to 0.28.
- Helmfile upgraded to 0.119.1.

### Breaking changes
- Adding anti-affinity to nodes in openstack will force them to be recreated by terraform. This will then break the kubernetes clusters.

### Release notes
- No migration path is available for adding anti-affinity in openstack.

### Added
- The master and worker VMs in openstack can now, optionally, have anti-affinity or soft anti-affinity. Soft anti-affinity is not available in Safespring.
- Documentation describing which api extensions that are used by ck8s.
- Customers now have rights to configure their Alertmanager.

### Fixed
- Added quotes to handle special characters (e.g for password etc) in cloud.conf.
- `ck8s dry-run` now takes config into account when determining which helmfile charts to diff.
- Default `startingDeadlineSeconds` of 200 for cronjobs and option to override the default value 
- Influxdb retention script runs for both service and workload cluster.
- Influxdb custom charts uses template name instead of hardcoded name.
- Tests respect the `ENABLE_FALCO` and `ENABLE_FALCO_ALERTS` configuration
- Fixed so nfs-kernel-server is installed on the nfs node.
- InfluxDB helm chart updated to version 4.7.0 (with InfluxDB version 1.8.0).
- Only a single alertmanager is installed in the workload cluster if `ENABLE_CUSTOMER_ALERTMANAGER=true`.
- Customer alertmanager is scraped by Prometheus in workload cluster so AlertmanagerDown alert is not fired.
- AlertmanagerDown alert in the service cluster for the alertmanager in the workload cluster is muted only when `ENABLE_CUSTOMER_ALERTMANAGER=false`.
- Customer alertmanager ingress is using the proper secret.

### Removed
- Unused elasticsearch output plugin parameters from fluentd.

### Changed
- Upgraded ck8sdash to v0.3.1