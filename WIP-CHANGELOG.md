### Breaking changes
- Adding anti-affinity to nodes in openstack will force them to be recreated by terraform. This will then break the kubernetes clusters.

### Release notes
- No migration path is available for adding anti-affinity in openstack.
- Mirgration of harbor to v.2.0.0 requires a manual garbage collaction. Please follow the steps described here: [https://goharbor.io/docs/1.10/administration/garbage-collection/]. Could be a good idea to backup aswell [https://github.com/elastisys/ck8s-ops/tree/master/backup/harbor].
- Migration of Grafana to 7.0.3 requires a manual database backup and restore to preserve the customer data. Please follow the steps described [here](docs/migration.md#service-cluster).
- If upgrading, manual removal of old elasticsearch, kibana, and exporter releases are required. Manual restoration of elasticsearch logs is required.

### Changed
- Curator now looks at the index name to determine its age instead of looking at the index creation date
- Nginx-ingress upgraded to 0.28.
- Helmfile upgraded to 0.119.1.
- Nodeport is now whitelisted for all cloud providers.
- Helm upgraded to 3.2.4.
- Harbor upgraded to 2.0.0.
- Customer and Ops Grafana upgraded to 7.0.3.
- Prometheus operator upgraded to version 8.15.11 and Prometheus to v2.19.2.
- InfluxDB Helm Chart upgraded to 4.8.1.
- InfluxDB now uses the upstream S3 backup jobs instead of our own solution.
- Prometheus Node exporter in InfluxDB Helm Chart upgraded to v1.0.1.
- Upgraded elasticsearch-prometheus-exporter chart version from 2.1.1 to 3.3.0.
- Renamed release `elasticsearch-prometheus-exporter` to `elasticsearch-exporter`.
- Elasticsearch-exporter now loads its credentials from a secret.
- Upgraded ck8sdash to v0.3.1

### Added
- The master and worker VMs in openstack can now, optionally, have anti-affinity or soft anti-affinity. Soft anti-affinity is not available in Safespring.
- Documentation describing which api extensions that are used by ck8s.
- Customers now have rights to configure their Alertmanager.
- Open Distro for Elasticsearch.
- Elasticsearch-backup helm chart for taking snapshots.
- Elasticsearch-slm helm chart for managing the lifecycle of snaphosts.

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
- Ansible role `internal_lb` sometimes getting stuck when running apt step
- Increased `interval` and `scrapeTimput` to 30s for elasticsearch prometheus service monitor.
- Tests respect the `ENABLE_CUSTOMER_GRAFANA` configuration
- Ensures that `customer kubeconfig.yaml` is added to the list of secrets. So it can be handled by the scripts.
- Fixed so that `loadbalancer_ip_addresses` is set for exoscale in `infra.json`
- Whitelist test for API server uses loadbalance IP.

### Removed
- Unused elasticsearch output plugin parameters from fluentd.
- InfluxDB Helm Chart moved out to a separate repository.
- Old elasticsearch and kibana setup.