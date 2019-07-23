#!/bin/sh

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform/system-services/

w1_ip=$(terraform output ss-worker1-ip)
w2_ip=$(terraform output ss-worker2-ip)
m_ip=$(terraform output ss-master-ip)

cat <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: harbor-pv
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /home
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $w1_ip
          - $w2_ip
          - $m_ip
EOF