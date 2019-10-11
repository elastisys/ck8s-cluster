# Backup procedure

Elasticsearch is set up to be able to store backups in a S3 bucket. There is also a CronJob in the cluster that will daily start a backup of elasticsearch via curl. All backups are incremental. 

To perform an on-demand backup, run the following command:

`curl -s -i -k -u "elastic:<password>" -XPUT "https://elastic.${ECK_SC_DOMAIN}/_snapshot/s3_backup_repository/<snapshot_name>"`

Where `<password>` should be changed to the elasticsearch password and `<snapshot_name>` should be changed to the name you want for the backup. The command will save the backup in the same bucket as the daily backups. 

During deployment, the following environment variables determine where the backups will be saved.


    S3_REGION -> The region in which the bucket is located, e.g. `ch-gva-2`
    S3_REGION_ENDPOINT -> The endpoint to reach the bucket, e.g. `https://sos-ch-gva-2.exo.io`
    S3_ACCESS_KEY -> The access key part of the required credentials to access the storage service.
    S3_SECRET_KEY -> The secret key part of the required credentials to access the storage service.
    S3_ES_BACKUP_BUCKET_NAME= -> The name of the bucket in S3

# Restore procedure

To restore elasticsearch from a backup, run the following command:

`curl -X POST "elastic.${ECK_SC_DOMAIN}/_snapshot/my_s3_repository/<snapshot_name>/_restore?pretty" -kL -u elastic:<password> -d '{"indices": "log*"}' -H 'Content-Type: application/json'`

Where `<password>` should be changed to the elasticsearch password and `<snapshot_name>` should be changed to the name of the backup to restore from. The daily backups will be named `snapshot-<year>.<month>.<day>` (e.g. `snapshot-2019.10.07`).

# Limitations

Restoring elasticsearch will fail if you try to restore indices (logs from a specific day) that are currently open in elastic search. E.g. if you take a backup, restart elasticsearch, and let fluentd start writing logs. Then when you try to restore, the current days index will be opened and can
t be restored from backup. The best way to fix this is to restore elasticsearch before letting fluentd or anything else write logs to elastic search. Another way is to rename the indices while restoring. 

See https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html for more info. 