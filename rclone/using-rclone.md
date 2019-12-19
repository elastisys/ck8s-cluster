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

A Kubernetes cronjob called `sync-buckets` is running in the service cluster in the namespace `kube-system`. The job executes the `rclone sync` command for all above listed buckets.

### How do i verify this?

You can look at the status of the pod that was created by the job. If successful the status should say `completed`. You can also look at the output from Rclone by looking at the output from the pod using `kubectl -n kube-system logs sync-buckets-...`


# Setup

**A word of warning:** since syncing can cause unintentional data loss, make sure that the configuration is correct not just once but at the very least twice. Also consider adding the `--dry-run` flag when you first set things up!

## Kubernetes cronjob

1. Set the required environment variables to access `osl1` and `sto2` S3 region endpoints.
    ```
    export OSL1_ACCESS_KEY_ID=
    export OSL1_SECRET_ACCESS_KEY_ID=
    export STO2_ACCESS_KEY_ID=
    export STO2_SECRET_ACCESS_KEY_ID=
    ```

2. Verify rclone configuration specified in `rclone.conf`. For all possible fields see https://rclone.org/s3/

3. Create secret containing the rclone configuration.

    ```
    envsubst < rclone.conf > rclone.conf.tmp && \
        kubectl create secret generic rclone-config --from-file=rclone.conf=rclone.conf.tmp -n kube-system && \
        rm rclone.conf.tmp
    ```

4. Check that the fields in `rclone-cron.yaml` are correct, if not update them accordingly. Pay special attention to.

    ```
    ...
    env:
    - name: BUCKETS_TO_SYNC
      value: "test-clone1 test-clone2"
    - name: REMOTE_SRC
      value: "safespring-sto2"
    - name: REMOTE_DST
      value: "safespring-osl1"
    - name: EXTRA_ARGS
      value: "--progress"
    ...
    ```


    - `BUCKETS_TO_SYNC`: the names of the buckets that are to be synced.
    - `REMOTE_SRC`: the remote source. Specified in rclone.conf.
    - `REMOTE_DST`: the remote destination. Specified in rclone.conf.
    - `EXTRA_ARGS`: extra arguments supplied to Rclone.

5. Deploy cronjob.
    ```
    kubectl apply -f rclone-cron.yaml -n kube-system
    ```

## Kubernetes pod

To quickly test to see if the configuration is correct or to force a sync you can start a kubernetes pod that will run immediatley. The steps are the same as that for the deployment of the cronjob but you have to make sure that the configuration is up-to date.

Also consider using `--dry-run` to see what will be copied and deleted by adding the flag to 
```
  env:
    ...
    - name: EXTRA_ARGS
      value: "--progress"
```
in the pod manifest `rclone-pod.yaml`.