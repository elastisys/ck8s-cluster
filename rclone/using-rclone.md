# Using Rclone

## Rclone overview

[Rclone](https://rclone.org/) is command line program to sync files and directories to and from multiple different storage solutions such as S3 storage. The program has the capabilities to [sync](https://rclone.org/commands/rclone_sync/) to and from network, e.g. using two different cloud accounts.

The sync operation is one-directional and ensures that the destination is kept identical with the source. Since unintentional data-loss can occur it is recommended to first run using the flag `--dry-run` to see what will be copied and deleted.

Syncing is used to ensure redundancy if one data-center is to blow up. Replication is not supported by safespring's S3 storage solution.


## Syncing S3 buckets

### What is synced?

Currently the following buckets are synced **from** the safespring S3 endpoint `sto2` **to** `osl1`.

- s3://elasticsearch-tempus-safespring-ck8s
- s3://influxdb-tempus-safespring-ck8s
- s3://psql-tempus-safespring-ck8s
- s3://velero-tempus-safespring-ck8s

### How and When are they synced?

The buckets are synced at 5 AM UTC every day.

For each bucket there is a Kubernetes cronjob `sync-<name of bucket>` running in the service cluster in the namespace `kube-system`. The jobs executes the `rclone sync` command.

### How do i verify this?

You can look at the status of the pods that was created by the jobs. If successful the status should say `completed`. You can also look at the output from Rclone by looking at the output from the pod using `kubectl -n kube-system logs sync-<name of bucket>-...`


# Setup

**A word of warning:** since syncing can cause unintentional data loss, make sure that the configuration is correct not just once but at the very least twice. Also consider adding the `--dry-run` flag when you first set things up!

## Kubernetes cronjobs

1. Set the required environment variables to access `osl1` and `sto2` S3 region endpoints.
    ```
    export OSL1_ACCESS_KEY_ID=
    export OSL1_SECRET_ACCESS_KEY_ID=
    export STO2_ACCESS_KEY_ID=
    export STO2_SECRET_ACCESS_KEY_ID=
    ```
    These are the only environment variable nessecary. The rest of the configuration has to be done manually!

2. Verify rclone configuration specified in `rclone.conf`. For all possible fields see https://rclone.org/s3/

3. Create secret containing the rclone configuration.

    ```
    envsubst < rclone.conf > rclone.conf.tmp && \
        kubectl create secret generic rclone-config --from-file=rclone.conf=rclone.conf.tmp -n kube-system && \
        rm rclone.conf.tmp
    ```

4. Modify the following fields in `setup-sync-cronjobs.sh`.

    ```
    # When should the jobs run?
    schedule='"0 5 * * *"'
    # What is the remote source?
    remote_src="safespring-sto2"
    # What is the remote destination?
    remote_dst="safespring-osl1"
    # What buckets should be synced?
    buckets="psql-tempus-safespring-ck8s influxdb-tempus-safespring-ck8s elasticsearch-tempus-safespring-ck8s velero-tempus-safespring-ck8s"
    ```

5. Deploy cronjobs.
    ```
    ./setup-sync-cronjobs.sh
    ```

## Kubernetes pod

To quickly test to see if the configuration is correct or to force a sync you can start a kubernetes pod that will run immediatley. The steps are the same as that for the deployment of the cronjobs. Run the following to deploy pods `./setup-sync-cronjobs.sh pod`.
Consider adding the flag `--dry-run` to see what will be copied and removed.