#!/bin/bash

set -e

manifest_tpl=rclone-cron.yaml.tpl

[ "$1" == "pod" ] && manifest_tpl=rclone-pod.yaml.tpl

schedule='"0 5 * * *"'
remote_src="safespring-sto2"
remote_dst="safespring-osl1"
buckets="psql-tempus-safespring-ck8s influxdb-tempus-safespring-ck8s elasticsearch-tempus-safespring-ck8s velero-tempus-safespring-ck8s"

# Deploy a cronjob for each bucket to sync.
for bucket in $buckets; do
    # This is appeneded to the name of the cronjob which limits the naming scheme of the buckets.
    export SYNC_SCHEDULE=$schedule
    export BUCKET_TO_SYNC=$bucket
    # The indentation is important!
    if [ "$1" == "pod" ]; then
        export RCLONE_ARGS=' 
    - "sync"
    - "'"${remote_src}"':'"${bucket}"'"
    - "'"${remote_dst}"':'"${bucket}"'"
    - "--log-level"
    - "DEBUG"'
    else
        export RCLONE_ARGS=' 
            - "sync"
            - "'"${remote_src}"':'"${bucket}"'"
            - "'"${remote_dst}"':'"${bucket}"'"
            - "--log-level"
            - "DEBUG"'
    fi
    
    envsubst < $manifest_tpl | kubectl -n kube-system apply -f -
done
