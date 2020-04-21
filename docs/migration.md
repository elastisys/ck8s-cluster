# Cluster migration

This document is a general guideline on how to migrate the data from one cluster to another. It may not work in all
cases but is a starting point for most situations.

## Workload cluster

This section describes how to migrate the workload of a cluster between releases with breaking changes

* Make sure all volumes you want to backup are annotated *(See [this](https://github.com/elastisys/ck8s/blob/master/docs/backup/velero.md#backup-of-kubernetes-resources-and-persistent-volumes-for-customers))*
* Do a backup of the old cluster, e.g.:
```
apiVersion: velero.io/v1
kind: Backup
metadata:
  labels:
    app.kubernetes.io/instance: velero
  name: migration-backup
  namespace: velero
spec:
  includedNamespaces:
  - default # Set to namespaces that includes the workload to migrate
  excludedResources:
  # Don't include certificate since the secret should still be valid
  # Cert-manager will still create a new certificate for the ingress
  - certificate.certmanager.k8s.io
  storageLocation: default
  ttl: 720h0m0s
  volumeSnapshotLocations:
  - default
```
For more information see [here](https://velero.io/docs/v1.3.2/api-types/backup/)

* Add the backupstoragelocation from the old cluster to the new cluster as read only, e.g.:
```
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: migration-storage
  namespace: velero
spec:
  config:
    region: ch-gva-2
    s3ForcePathStyle: "true"
    s3Url: https://sos-ch-gva-2.exo.io
  objectStorage:
    bucket: some-bucket-name
    prefix: workload-cluster
  accessMode: "readOnly"
  provider: aws
```
For more information see [here](https://velero.io/docs/v1.3.2/api-types/backupstoragelocation/)

* Make sure that the backup is accessible from the new cluster by running `kubectl get backups -n velero`
* Restore the new cluster with the backup from earlier
```
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: migration-restore
  namespace: velero
spec:
  backupName: migration-backup
```
For more information see [here](https://velero.io/docs/v1.3.2/api-types/restore/)

* Wait for everything to be running and make sure it works as intended
* Make sure cert-manager has created new certificates for the ingresses (they might be not-ready)
* Change DNS to the new cluster.
  * This can be done by changing `TF_VAR_dns_prefix` in the old cluster to something else and setting the old value in the new cluster.
* The old cluster should now be ready to tear down

## Service cluster

This section describes how to migrate the service cluster between releases with breaking changes

* Migrate elasticsearch data *(see [this](backup/elasticsearch.md))*
* Migrate influx data *(see [this](backup/influxdb.md))*
* Migrate harbor data *(see [this](backup/harbor.md))*
* Migrate customer grafana dashboards
  * Two options is possible here:
    1. Copy the grafana DB from the pod
    ```
    kubectl cp -c grafana monitoring/<grafana pod name>:/var/lib/grafana/grafana.db $(pwd)/grafana.db.bck
    ```
    Restore a new grafana instance by copy it back
    ```
    kubectl cp -c grafana $(pwd)/grafana.db.bck monitoring/<grafana pod name>:/var/lib/grafana/grafana.db
    ```
    2. Use velero as described above to backup and restore the customer grafana
