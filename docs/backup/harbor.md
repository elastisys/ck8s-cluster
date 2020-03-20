# Backup procedure

Harbor is set up to be able to store backups in a S3 bucket. There is also a CronJob
in the cluster that will daily start a backup of harbor by backing up the postgres database.
The backup is run with a image `elastisys/backup-postgres`. This image includes the postgres
and aws CLI. This [Dockerfile](https://github.com/elastisys/backup-postgres/blob/master/Dockerfile) 
can be used to build and update the image.

To perform an on-demand backup:

```
export PG_HOSTNAME=localhost
export DAYS_TO_RETAIN=7
export S3_BUCKET=harbor-bucket-name
export S3_REGION_ENDPOINT=eg.<https://sos-ch-gva-2.exo.io>
export AWS_ACCESS_KEY_ID=id-to-s3-account
export AWS_SECRET_ACCESS_KEY=key-to-s3-account
kubectl port-forward -n harbor harbor-harbor-database-0 5432:5432
./backup-harbor.sh
```
`backup-harbor.sh` can be found in https://github.com/elastisys/ck8s-ops/tree/master/backup/harbor

During deployment, the following environment variables determine where the backups will be saved.

    S3_REGION_ENDPOINT -> The endpoint to reach the bucket, e.g. `https://sos-ch-gva-2.exo.io`
    S3_ACCESS_KEY -> The access key part of the required credentials to access the storage service.
    S3_SECRET_KEY -> The secret key part of the required credentials to access the storage service.
    S3_HARBOR_BUCKET_NAME -> The name of the bucket in S3. Will add a suffix of `/backups`.
    HARBOR_DB_PWD -> Password to the `postgres` user in the database.
    
# Restore procedure

To restore elasticsearch from a backup do these steps:
OBS! this will remove the current data in the active database.
 
```
export S3_BUCKET=harbor-bucket-name
export S3_REGION_ENDPOINT=eg.<https://sos-ch-gva-2.exo.io>
export AWS_ACCESS_KEY_ID=id-to-s3-account
export AWS_SECRET_ACCESS_KEY=key-to-s3-account 
kubectl scale deployment --replicas=0 -n habror --all
kubectl port-forward -n harbor harbor-harbor-database-0 5432:5432
./restore-harbor.sh
kubectl scale deployment --replicas=1 -n habror --all
```

The `restore-harbor.sh` script can be found in https://github.com/elastisys/ck8s-ops/tree/master/backup/harbor

This will restore everything that was originally in the backuped cluster.
There is no point in time backups or similar so data between restoration and last
backup will be lost. 

A restoration can not be done while users or services are connected to the database. This
will result in downtime while running the restoration.