### Added

- Customer RBAC for managing ServiceMonitors, PodMonitors and PrometheusRules
- Initial version of configuration and command facade.
- SOPS secrets management.

### Changed

- Influxdb is now deployed from a fork of the stable/influxdb chart, instead of using Kustomize to modify the original.
- Pipeline only tests Harbor if `ENABLE_HARBOR` is set to true.
- Refactorization of configuration repositories.

### Removed

- Kustomize is no longer needed and has been removed.
- Vault secrets management.

### Fixed

- Invalid index selection in SLM policy for nightly elasticsearch snapshots.
