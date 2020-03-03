
## Added

- Use elasticsearch's SLM to manage the lifecycle of snapshots.

## Updated

- Naming convention for RKE clusters.

## Removed

- Elasticsearch backup cronjob that was used prior to SLM to invoke the snapshot api in elasticsearch.