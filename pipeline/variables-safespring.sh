#!/bin/bash

export ECK_BASE_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name')
export ECK_OPS_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name' | sed 's/^/ops./')
export CERT_TYPE=staging

source common-env.sh

export S3_REGION=sto1
export S3_REGION_ENDPOINT=https://s3.sto1.safedc.net
export S3_HARBOR_BUCKET_NAME=harbor-pipeline
export S3_VELERO_BUCKET_NAME=velero-pipeline
export S3_ES_BACKUP_BUCKET_NAME=elasticsearch-pipeline
export S3_INFLUX_BUCKET_URL=s3://influxdb-pipeline

# Disable alerts
export ALERT_TO=null
# In case we want alerts at some point
export SLACK_API_URL=https://hooks.slack.com/services/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

export OAUTH_ALLOWED_DOMAINS="example.com"

#This is the home folder when the container is built, but not when it is executed in github actions
export HELM_HOME=/root/.helm