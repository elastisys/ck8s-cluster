# Incidents

This document describes incidents that we have encountered.
The goal is to be able to learn, spread knowledge and avoid problems in the future.

## 2020-01-20 - Elasticsearch health unknown, pods initializing

**Cloud provider:** Safespring
**Environment:** Tempus
**Cluster:** service cluster

### In what state was the cluster

Two of three elasticsearch pods were stuck initializing, the third was running.
The elasticsearch cluster health showed "unknown".

The two pods that were stuck initializing did not manage to mount the data volume.
Logs (see below) from the kubelet indicated that the node status did not show the volume as mounted after trying to mount it.
In Safespring's web GUI, the volumes showed as attached to the correct VMs.
It is unknown what this looked like from the VM itself (did the volume show up in the filesystem or not?).

```
I0120 06:07:56.686034    4962 reconciler.go:203] operationExecutor.VerifyControllerAttachedVolume started for volume "pvc-fc31cdd6-bace-498b-8aa4-bede891e38c4" (UniqueName: "kubernetes.io/cinder/1ffb10df-eac1-4923-8bde-017955eed96a") pod "elasticsearch-es-nodes-0" (UID: "716f3cf9-1c65-41d5-ac6d-046b8a9ab93c")
E0120 06:07:56.690633    4962 nestedpendingoperations.go:270] Operation for "\"kubernetes.io/cinder/1ffb10df-eac1-4923-8bde-017955eed96a\"" failed. No retries permitted until 2020-01-20 06:09:58.690574423 +0000 UTC m=+591079.290842552 (durationBeforeRetry 2m2s). Error: "Volume not attached according to node status for volume \"pvc-fc31cdd6-bace-498b-8aa4-bede891e38c4\" (UniqueName: \"kubernetes.io/cinder/1ffb10df-eac1-4923-8bde-017955eed96a\") pod \"elasticsearch-es-nodes-0\" (UID: \"716f3cf9-1c65-41d5-ac6d-046b8a9ab93c\") "
```

### Solution

Detach the affected volumes through Safespring's API or web GUI.
The volumes were then attached by Kubernetes as normal and the pods could initialize successfully.

### What was the likely cause for the cluster state

Safespring had multiple problems (API issues and loss of network) during the weekend which may have caused the volumes and nodes to end up in this situation.
Unfortunately, we cannot be sure what exactly caused it.

### Lessons learned

- Inconsistencies between what the cloud provider and Kubernetes APIs can prevent self healing inside the cluster.
- Resetting the state (turn off and on again, detach and attach again, etc.) can help in many situations.

## 2020-01-08 - Website API server not responding

**Cloud provider:** Safespring
**Environment:** website
**Cluster:** workload cluster

### In what state was the cluster

The API server timed out most requests, although at least `kubectl get componentstatuses` worked (all in components had unknown status).

The master had a disk usage of 100%.

### What was the likely cause for the cluster state

The master nodes disk had filled up completely with audit logs.

### Lessons learned

- Not much really.
  We already know that we need to monitor disk usage and set retention policies.
  This cluster was just not monitored that closely and not updated to include the retention config.

## 2020-01-02 - Elasticsearch red health

**Cloud provider:** Safespring
**Environment:** tempus-testing
**Cluster:** service cluster

### In what state was the cluster

One of the elasticsearch pods was `Evicted`, the other two running normally.
The elasticsearch operator pod and kibana were both running normally and kibana was usable.
Influxdb was in a crash loop, both the backup job and the database itself.

After the evicted pod was deleted, a new pod was created.
The elasticsearch cluster health became `yellow` instead, but got stuck there as some shards remained unassigned.

### What was the likely cause for the cluster state

Influxdb was crashing because it was `OOMKilled`.
It is not clear why the elasticsearch pod was evicted but it may have been because influx was using up so much memory on the node.

The reason why some shards remained unassigned was that all elasticsearch nodes (pods) were low on disk space.
This could be seen in the logs from the elasticsearch master.

### Lessons learned

- Evicted pods are not automatically cleaned up and replaced.
- Elasticsearch may get stuck in yellow state when low on disk space.

## 2019-12-19 - Unable to delete or create pods

**Cloud provider:** Safespring
**Environment:** website
**Cluster:** workload cluster

### In what state was the cluster

The kubernetes master components was up and running. The kubelet on the worker node tried to register itself as a node but it could not perform the operation because it got `connection timout` while trying to talk to the kube-apiserver. The kube-apiserver was reachable outside of the cluster although normal operations such as scaling deployments and deleting pods did not have the desired behaviour. Essentialy pods could not be deleted or started.

### What was the likely cause for the cluster state

All master components and the kublet on both the master and worker nodes were up and running. Looking at logs did not give any decisive answer but after a while we came to the conclusion that the reason for the connection timeout when the kubelet was trying to talk to the kube-apiserver was because of the network component `canal` being evicted from the master node.

Our suspicions fell onto OPA that we thought might be the culprit denying requests to the apiserver. While fetching the available `validating admissionWebhooks` we saw that there was an error trying to get Cert-manager's webhook. We deleted both webhooks and the cluster returned to its normal state.

The most likley cause was Cert-manager's webhook. We deleted both webhooks at the same time so we can not be entirely sure that it **actually** was cert-manager and not OPA's webhook that interfered. Looking at the logs from OPA did not suggest that there was anything strange happening.

### Lessons learned

If all kubernetes components are up and running it might be worth to take a look at and see what admission webhooks are present in the cluster to see if they are interfering cluster operations.
