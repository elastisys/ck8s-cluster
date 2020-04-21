# Backup procedure

Elasticsearch is set up to be able to store backups in a S3 bucket. There is also a CronJob in the cluster that will
daily start a backup of elasticsearch via curl. All backups are incremental.

To perform an on-demand backup, run the following command:

**NOTE: Make sure you have a s3 backup repository present on elasticsearch that you can backup to**

```
curl -X PUT -siL -u "elastic:<password>"  "https://elastic.${ECK_OPS_DOMAIN}/_snapshot/<s3_backup_repository_name>/<snapshot_name>"
```

Where `<password>` should be changed to the elasticsearch password and `<snapshot_name>` should be changed to the name
you want for the backup. The command will save the backup in the same bucket as the daily backups.

During deployment, the following environment variables determine where the backups will be saved.


```
S3_REGION -> The region in which the bucket is located, e.g. `ch-gva-2`
S3_REGION_ENDPOINT -> The endpoint to reach the bucket, e.g. `https://sos-ch-gva-2.exo.io`
S3_ACCESS_KEY -> The access key part of the required credentials to access the storage service.
S3_SECRET_KEY -> The secret key part of the required credentials to access the storage service.
S3_ES_BACKUP_BUCKET_NAME= -> The name of the bucket in S3
```

# Restore procedure

To restore elasticsearch from a backup, run the following command:

```
curl -X POST "https://elastic.${ECK_OPS_DOMAIN}/_snapshot/my_s3_repository/<snapshot_name>/_restore?pretty" \
  -siL -u elastic:<password> -d '{"indices": "kubeaudit*,kubecomponents*,kubernetes*"}' \
  -H 'Content-Type: application/json'
```

Where `<password>` should be changed to the elasticsearch password and `<snapshot_name>` should be changed to the name
of the backup to restore from. The daily backups will be named `snapshot-<year>.<month>.<day>` (e.g.
`snapshot-2019.10.07`).

This can be done in the interface as well by going to *Management* -> *Snapshot and Restore* and restore from the latest
snapshot. On indices, deselect "All indices, including system indices", press "Use index patterns" and add `kubeaudit-*`,
`kubernetes-*` and `other-*` as patterns. Continue to Review and press "JSON" and it should look something like this:

```
{
  "indices": "kubeaudit-*,kubernetes-*,other-*"
}
```

## Disaster recovery

Remember to stop the ingress flow to elasticsearch until the indices have been
restored.

Examples:

To stop traffic to be inserted into elasticsearch
```
kubectl -n elastic-system get ingress elasticsearch -o json \
    | jq '(.spec.rules[].http.paths[].backend.serviceName | select(. == "elasticsearch-es-http")) |= "temp-nonexisting"' \
    | kubectl apply -f -
```

To start traffic to be inserted into elasticsearch again. **Assumes previous command was used to stop**
```
kubectl -n elastic-system get ingress elasticsearch -o json \
    | jq '(.spec.rules[].http.paths[].backend.serviceName | select(. == "temp-nonexisting")) |= "elasticsearch-es-http"' \
    | kubectl apply -f -
```

## Recreating cluster

Remember to re-run the `configure-es` job when restoring elasticsearch on a
recreated cluster.

## Restoring users

To restore users you need to restore the `.security-*` index from a snapshot.
However, before you restore it, the index first needs to be deleted.
Read more [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/restore-security-configuration.html).

# Migration

The procedure to migrate elasticsearch data between clusters is similar to backup/restore.

**NOTE: This process assumes that elasticsearch uses the same version, since migrating data between versions may need
additional data modification.**

These are the steps to migrate a cluster.

1. Create a new cluster.
1. Add the backup bucket from the old cluster as a read-only repository. (Described [here](#add-backup-bucket))
1. Take snapshot on the old cluster.
1. Stop ingress of logs to new cluster. *(Described [here](#disaster-recovery)*
1. Delete the default indices. *(kubeaudit-\*, kubernetes-\* and other-\*)*
1. Restore the snapshot from the old cluster as described [here](#restore-procedure).
1. Start ingress of logs to the new cluster again.
1. Delete index `.security-7` in the new cluster.
1. Restore index `.security-7` from the snapshot.

## Add backup bucket

*Assuming you are using the same s3 store as the old cluster. Otherwise you must add a new s3 client to the k8s secret
s3-credentials in elastic-system namespace.*

To add a bucket to elasticsearch you can log in to Kibana and go to *Management* -> *Snapshot and Restore* ->
*Repositories*. Press "Register a repository", give it a name and select repository type AWS S3.

Set the client name to be "default" *(Assuming you didn't need to add a new s3 client)*, set the bucket name to be the
same name as the old cluster uses and make sure that the "Read-only" option is set at the bottom of the page. Press
register, go to the list of repositories and make sure that it works.

# Limitations

Restoring elasticsearch will fail if you try to restore indices (logs from a specific day) that are currently open in
elasticsearch. E.g. if you take a backup, restart elasticsearch, and let fluentd start writing logs. Then when you try
to restore, the current days index will be opened and can't be restored from backup. The best way to fix this is to
restore elasticsearch before letting fluentd or anything else write logs to elastic search. Another way is to rename the
indices while restoring.

See https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html for more info.
