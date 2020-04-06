# Compliant Kubernetes changelog
<!-- BEGIN TOC -->
- [v0.2.1](#v021---2020-04-03)
- [v0.2.0](#v020---2020-03-26)
- [v0.1.0](#v010---2020-03-06)
<!-- END TOC -->

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
