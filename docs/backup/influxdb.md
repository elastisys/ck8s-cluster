# Backup procedure

In the cluster there is a CronJob that is once per day performing full backups of all databases.
This document describes the procedure to perform, not manual, but on-demand backups.

To perform an on-demand backup to S3 compatible storage run the following command:

```
kubectl -n influxdb-prometheus create job <job-name> --from=cronjob/influxdb-backup
```

A backup will be deployed in the cluster named `influxdb-backup`. It will run until completetion but it will not restart if any container fails!

When the backup is completed, to find out the name of the directory that was used. Run this command:

```
kubectl logs -n influxdb-prometheus -l job-name=<job-name> | grep -oP "$S3_INFLUX_BUCKET_NAME/backup_[0-9_]+" | tail -n 1 | cut -d '/' -f 2
```

## Restore procedure

To restore InfluxDB from a desired backup begin be setting the backup's name as a variable.

```
export INFLUX_BACKUP_NAME="backup_xxxxxxxx_xxxxxx"  # Name of the backup (the directory)
```

Then you can use the configuration file of the cluster.

```
source $CK8S_CONFIG_PATH/config.sh
```

And use the secrets file to load the rest.

```
sops exec-env $CK8S_CONFIG_PATH/secrets.env 'envsubst < manifests/restore/restore-influx.yaml' | kubectl apply -n influxdb-prometheus -f -
```

If you manually want to add all the values these are the variables that are used

```
export INFLUX_BACKUP_NAME="backup_xxxxxxxx_xxxxxx"  # Name of the backup (the directory)

export S3_REGION="ch-gva-2"                                 # Name of the s3 region
export S3_REGION_ENDPOINT="https://sos-ch-gva-2.exo.io"     # S3 endpoint
export S3_INFLUX_BUCKET_NAME="cluster-name-influxdb"        # Name of the S3 bucket
export INFLUX_ADDR="influxdb.influxdb-prometheus.svc:8088"  # Address (internal) to influx

export S3_ACCESS_KEY="s3_access_key"  # The access key to S3
export S3_SECRET_KEY="s3_secret_key"  # The secret key to S3
```

With all variables in place execute

```
envsubst < manifests/restore/restore-influx.yaml | kubectl -n influxdb-prometheus apply -f -
```

## Migration

The migration process is much like backup and restore only that the restore is not on the same cluster.

The steps that are needed to be taken are:

* Take a backup from the old cluster
* Restore the backup in the new cluster using the migration manifest *(`manifests/restore/migration-influx.yaml`)*

With kubectl pointing to the new cluster and `CK8S_CONFIG_PATH` pointing to the old cluster and `INFLUX_BACKUP_NAME`
being set to the latest backup that was made in the old cluster. Run the following command:

**NOTE:** This will drop the database and restore with the backup. So all data old will be lost. If you want
to merge the data follow
[this](https://docs.influxdata.com/influxdb/v1.8/administration/backup_and_restore/#restore-examples) procedure *(This
requires **ALOT** of memory and time and do not complete successfully every time)*.

```
export INFLUX_BACKUP_NAME="backup_xxxxxxxx_xxxxxx"  # Name of the backup (the directory)
```

Then you can use the configuration file of the old cluster.

```
source $CK8S_CONFIG_PATH/config.sh
```

And use the secrets file to load the rest.

**NOTE:** Make sure you have `KUBECONFIG` set to the new cluster.

```
sops exec-env $CK8S_CONFIG_PATH/secrets.env 'envsubst < manifests/restore/migrate-influx.yaml' | kubectl -n influxdb-prometheus apply -f -
```

If you manually want to add all the values these are the variable that are used in addition to the once in the
[restore section](#restore-procedure).

```
export INFLUXDB_PWD="supersecret" # The password for the influxDB
```

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
