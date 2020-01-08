# Incidents

This document describes incidents that we have encountered.
The goal is to be able to learn, spread knowledge and avoid problems in the future.

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
