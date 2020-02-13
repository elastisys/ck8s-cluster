## Backup of kubernetes resources and persistent volumes for customers
Velero is used to take backups of the customers kubernetes resources and persistent volumes.

This is currently only meant for disaster recovery when the whole clusters needs to be restarted. But it could also be used by customers to rollback certain applications to an earlier state.

Our deployment includes Velero in the workload_cluster which will take daily backups of all kubernetes resources with the lable `velero: backup`. Persistent volumes will be backed up if they are tied to a pod with the previously mentioned lable and if that pod is annotated with `backup.velero.io/backup-volumes=<volume1>,<volume2>,...`, where the value is a comma separated list of the volume names. 

To restore the state from that backup, first download the Velero cli: https://github.com/vmware-tanzu/velero/releases (version 1.1.0).
Then run `velero restore create --from-schedule velero-daily-backup`, add `-w` if you want the command to wait until the restore is complete. Make sure that `KUBECONFIG` is exported as an environment variable when you run the restore command.

Persistent volumes are only restored if a pod with the backup annotation is restored. Multiple pods can have an annotation for the same persistent volume. When restoring the persistent volume it will overwrite any existing files with the same names as the files to be restored. Any other files will be left as they were before the restoration started. So a restore will not wipe the volme clean and then restore. If that's the wantad behaviour, then the volume must be wiped manually before restoring.

## Restore service cluster from Velero backup

To restore the service cluster from a Velero backup, set the environment
variable `RESTORE_VELERO=true`.

By default the latest scheduled backup will be restored. To restore from a
specific backup set the environment variable `VELERO_BACKUP_NAME`.
