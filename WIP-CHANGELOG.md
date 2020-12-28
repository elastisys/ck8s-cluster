### Release notes

- The creation and deletion of S3 buckets is no longer handled by this module.
This means that the following configuration fields have been deprecated and are no longer in use:
  - `s3_es_backup_bucket_name`
  - `s3_harbor_bucket_name`
  - `s3_influx_bucket_name`
  - `s3_sc_fluentd_bucket_name`
  - `s3_velero_bucket_name`
  - `s3_region_address`
  - `s3_access_key`
  - `s3_secret_key`

### Removed

- Management of S3 buckets has been removed.
