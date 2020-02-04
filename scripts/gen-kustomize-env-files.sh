#!/bin/bash

function write_env_vars_to_file() { # arguments: file, env_vars
    local file="$1"
    shift
    local env_vars=("$@")
    echo "# File generated from environment variables" > $file

    for env_var in ${env_vars[@]}
    do
        printf '%s=%s\n' $env_var "${!env_var}" >> $file
    done
}

env_vars=("INFLUX_ADDR" "S3_REGION" "S3_REGION_ENDPOINT" "S3_INFLUX_BUCKET_URL")
file=./kustomize/influxdb/base/influxdb-backup/backup-influx.env
write_env_vars_to_file $file "${env_vars[@]}"

env_vars=("S3_ACCESS_KEY" "S3_SECRET_KEY")
file=./kustomize/influxdb/base/influxdb-backup/secret.env
write_env_vars_to_file $file "${env_vars[@]}"

env_vars=("INFLUXDB_USER" "INFLUXDB_PWD")
file=./kustomize/influxdb/base/secret.env
write_env_vars_to_file $file "${env_vars[@]}"