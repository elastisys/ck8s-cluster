# For harbor image chart storage and velero backup storage
export S3_REGION=de-fra-1
export S3_REGION_ENDPOINT=https://sos-de-fra-1.exo.io
export S3_HARBOR_BUCKET_NAME=harbor-bucket
export S3_VELERO_BUCKET_NAME=velero-bucket

# Influx cronjob backup variables.
export INFLUX_ADDR=influx.influxdb-prometheus.svc:8088
export S3_INFLUX_BUCKET_URL=s3://influxdb-backups
export INFLUX_BACKUP_SCHEDULE="0 0 * * *"

# Elasticsearch
export S3_ES_BACKUP_BUCKET_NAME=
