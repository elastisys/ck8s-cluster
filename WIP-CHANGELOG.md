
## Added

- Customer RBAC for managing ServiceMonitors, PodMonitors and PrometheusRules

## Changed

- Influxdb is now deployed from a fork of the stable/influxdb chart, instead of using Kustomize to modify the original.

## Removed

- Kustomize is no longer needed and has been removed.
