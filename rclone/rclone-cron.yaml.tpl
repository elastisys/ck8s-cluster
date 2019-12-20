apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: sync-$BUCKET_TO_SYNC
  labels:
    app: sync-$BUCKET_TO_SYNC
spec:
  schedule: $SYNC_SCHEDULE
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: sync-$BUCKET_TO_SYNC
        spec:
          restartPolicy: Never
          tolerations:
          - key: "nodeType"
            operator: "Equal"
            value: "elastisys"
            effect: "NoSchedule"
          volumes:
          - name: rclone-config
            secret:
              secretName: rclone-config
          containers:
          - name: rclone
            image: elastisys/rclone-sync:1.1.0
            command: ["rclone"]
            args: $RCLONE_ARGS
            volumeMounts:
            - name: rclone-config
              mountPath: /root/.config/rclone/
            resources:
              requests:
                cpu: 50m
                memory: 100Mi
              limits:
                cpu: 2000m
                memory: 4000Mi
