#!/bin/bash

# Note: during the migration, we disable remoteRead to avoid slow queries
# when prometheus would try to reach influx while it is down.

# 1. Disable remote read for prometheus
# 2. Take a backup of influxdb by spawning a backup job from the backup cronjob
# 3. Purge the influxdb helm release
# 4. Install new influxdb helm release (reuse old PVC)
# 5. Enable remote read again for prometheus

set -eu -o pipefail

# Inlfux backup variables.
: "${INFLUX_ADDR:?Missing INFLUX_ADDR}"
: "${S3_INFLUX_BUCKET_NAME:?Missing S3_INFLUX_BUCKET_NAME}"
# General aws S3 cli variables.
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"

here="$(dirname "$(readlink -f "$0")")"

################################
## 0. Get confirmation from user
################################

echo
echo "You are about to migrate influxdb."
echo "This WILL purge the old helm release and install the new chart instead."
echo "Make sure you are using the correct kubeconfig and context!"
echo
echo "Your environment is as follows:"
echo "\$KUBECONFIG=${KUBECONFIG}"
echo "Context: $(kubectl config current-context)"

read -p "Do you want to continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

##############################################
## 1. Disable remote read for prometheus
##############################################

# Store current remote read values
WC_SCRAPER_READ_URL=$(kubectl -n monitoring get prometheuses \
    wc-scraper-prometheus-instance \
    -o jsonpath="{.spec.remoteRead[0].url}")
SC_PROMETHEUS_READ_URL=$(kubectl -n monitoring get prometheuses \
    prometheus-operator-prometheus \
    -o jsonpath="{.spec.remoteRead[0].url}")

echo "Disable prometheus remote read"
kubectl -n monitoring patch prometheuses wc-scraper-prometheus-instance \
    --type json -p='[{"op": "remove", "path": "/spec/remoteRead"}]'
kubectl -n monitoring patch prometheuses prometheus-operator-prometheus \
    --type json -p='[{"op": "remove", "path": "/spec/remoteRead"}]'

###############################
## 2. Take a backup of influxdb
###############################

echo "Create backup job for influxdb and wait for it to finish"
kubectl -n influxdb-prometheus create job migration-backup \
    --from=cronjob/influxdb-backup --dry-run -o yaml > migration-backup-job.yaml
# Set a specific name so we can find the backup and restore from it
INFLUX_BACKUP_NAME="migration_backup_v0.1.0-v0.2.0"
sed --in-place 's/backup_$(date +%Y%m%d_%H%M%S)/'${INFLUX_BACKUP_NAME}'/' migration-backup-job.yaml

# Run the backup job and wait for it to finish
kubectl -n influxdb-prometheus apply -f migration-backup-job.yaml
kubectl -n influxdb-prometheus wait job/migration-backup \
    --for=condition=complete --timeout=1h
kubectl -n influxdb-prometheus logs job/migration-backup > migration-backup.log
echo "Influxdb has been backed up by the Job 'migration-backup'."
echo "The backup is stored in the pre-configured S3 bucket and is named"
echo "${INFLUX_BACKUP_NAME}"
echo "The logs can be found in migration-backup.log"

rm migration-backup-job.yaml

########################
## 3. Purge old influxdb
########################

cd ${here}/../../helmfile/

helmfile -f helmfile.yaml -e service_cluster -l app=influxdb --interactive destroy

echo "Cleaning up old influxdb chart and kustomization"
# This file was created as part of installation of the old influxdb chart.
# It must be removed or helm will include it together with the other templates
# resulting in duplicate definitions of many kubernetes objects.
# If the chart was installed from another computer or folder it may not exist.
if [[ -f charts/influxdb/templates/all.yaml ]]
then
    echo "Removing: charts/influxdb/templates/all.yaml"
    rm charts/influxdb/templates/all.yaml
fi
if [[ -d kustomize ]]
then
    echo "Removing folder: kustomize"
    rm --recursive kustomize
fi

##########################
## 4. Install new influxdb
##########################

# The old PVC remains and can be used by the new Pod! 🎉

helmfile -f helmfile.yaml -e service_cluster -l app=influxdb --interactive apply --suppress-diff

####################################
## 5. Enable remote read again
####################################

echo "Enable prometheus remote read again"
kubectl -n monitoring patch prometheuses wc-scraper-prometheus-instance \
    --type json -p='[{"op": "add", "path": "/spec/remoteRead", "value": ["url": "'${WC_SCRAPER_READ_URL}'"]}]'
kubectl -n monitoring patch prometheuses prometheus-operator-prometheus \
    --type json -p='[{"op": "add", "path": "/spec/remoteRead", "value": ["url": "'${SC_PROMETHEUS_READ_URL}'"]}]'

echo "SUCCESS!"
echo
echo "Note: A backup was taken during the migration. It is stored in the"
echo "pre-configured S3 bucket and is named ${INFLUX_BACKUP_NAME}"
echo "The logs from this backup can be found in migration-backup.log"
