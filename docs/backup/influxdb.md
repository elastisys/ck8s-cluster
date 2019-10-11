# Backup procedure

In the cluster there is a CronJob that is once per day performing full backups of all databases.
This document describes the procedure to perform, not manual, but on-demand backups.

To perform an on-demand backup to S3 compatible storage deploy the manifest `manifests/backup/backup-influx.yaml`.
The manifest contains a pod template with one init-container and one container.
The init-container runs the `influxdb` image and it connects to the influxdb instance, performs the backup, and saves it at the path `/backup`.
The backup will be named `backup_$(date +%Y%m%d_%H%M%S)`.
Once the init-container is finished the main conatiner, which runs Atlassians `pipelines-awscli` image, streams the backup to an S3 compatible storage.

Before the manifest can be deployed the following environment variables needs to to be set

    INFLUX_ADDR -> The address, including the rpc port, from which influxdb can be reached from within the Kubernetes cluster, e.g. influxdb.influxdb-prometheus.svc:8088
    S3_INFLUX_BUCKET_URL -> The URL to the bucket where you want the backup to be stored, e.g. `s3://influxdb-backups` 

    S3_REGION -> The region in which the bucket is located, e.g. `ch-gva-2`
    S3_REGION_ENDPOINT -> The endpoint to reach the bucket, e.g. `https://sos-ch-gva-2.exo.io`
    S3_ACCESS_KEY -> The access key part of the required credentials to access the storage service.
    S3_SECRET_KEY -> The secret key part of the required credentials to access the storage service.

Once the environment variables have been assigned, execute the following command to substitute the variables in the manifest and deploy it

    envsubst < manifests/backup/backup-influx.yaml | kubectl -n influxdb-prometheus apply -f -

A backup will be deployed in the cluster named `influxdb-backup`. It will run until completetion but it will not restart if any container fails!


## Restore procedure

To restore InfluxDB from a desired backup begin be setting the backup's name as a variable.

    INFLUX_BACKUP_NAME -> The name of the backup (the directory), e.g. `backup_20191009_054238`

The restore procedure also requires the same variables as in the backup procedure!

With all variables in place execute

    envsubst < manifests/restore/restore-influx.yaml | kubectl -n influxdb-prometheus apply -f -

## Limitations

Now only **full** backups are taken from InfluxDB. It would be optimal to perform daily **incremental** backups instead.
The reason for only performing full backups is because of the inability to do a full restore from incremental backups.
If a database is already present in the InfluxDB server then that database cannot be restored from the backup.
To get around that problem one can restore that specific database into a new database and side-load it into the desired database.
This procedure has to be repeated for each database, which is not that hard since we only have two databases but it will become cumbersome if you want to restore lets say 30 incremental backups.
Then you have to repeat the procedure of side-loading data for each incremental backup for each database.

Now, this incremental restore process can probably be made automatic and it should therefore be implemented in the future.

No load testing has been performed to see how much resources are consumed by the processes when performing backups and restores.
Neither has the time consumed been measured to see how long it would take to restore/backup a larger dataset.


## More info

More information regarding backup and restore can be found at <https://docs.influxdata.com/influxdb/v1.7/administration/backup_and_restore/>