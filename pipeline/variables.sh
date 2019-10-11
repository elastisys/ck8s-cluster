#!/bin/bash

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
pushd "${SCRIPTS_PATH}/../" > /dev/null

export ECK_WC_DOMAIN=$(cat infra.json | jq -r '.workload_cluster.dns_name' | sed 's/[^.]*[.]//')
export ECK_SC_DOMAIN=$(cat infra.json | jq -r '.service_cluster.dns_name' | sed 's/[^.]*[.]//')

popd > /dev/null

export S3_ACCESS_KEY=$EXOSCALE_API_KEY
export S3_SECRET_KEY=$EXOSCALE_SECRET_KEY
export S3_REGION=ch-gva-2
export S3_REGION_ENDPOINT=https://sos-ch-gva-2.exo.io
export S3_HARBOR_BUCKET_NAME=harbor
export S3_VELERO_BUCKET_NAME=velero
export S3_ES_BACKUP_BUCKET_NAME=es-backup
# Influx backup variables
export INFLUX_ADDR=influx.influxdb-prometheus.svc:8088
export S3_INFLUX_BUCKET_URL=s3://influxdb-backups
export INFLUX_BACKUP_SCHEDULE="0 0 * * *"