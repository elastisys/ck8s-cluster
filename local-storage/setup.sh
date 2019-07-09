#!/bin/bash

mkdir -p /mnt/disks/vol1
mount -t tmpfs vol1 /mnt/disks/vol1

kubectl apply -f test.yaml