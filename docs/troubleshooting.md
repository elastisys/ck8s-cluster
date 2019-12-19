
## 2019-12-19 - Website workload cluster

### In what state was the cluster

The kubernetes master components was up and running. The kubelet on the worker node tried to register itself as a node but it could not perform the operation because it got `connection timout` while trying to talk to the kube-apiserver. The kube-apiserver was reachable outside of the cluster although normal operations such as scaling deployments and deleting pods did not have the desired behaviour. Essentialy pods could not be deleted or started.

### What was the likley cause for the cluster state

All master components and the kublet on both the master and worker nodes were up and running. Looking at logs did not give any decisive answer but after a while we came to the conclusion that the reason for the connection timeout when the kubelet was trying to talk to the kube-apiserver was because of the network component `canal` being evicted from the master node. 

Our suspicions fell onto OPA that we thought might be the culprit denying requests to the apiserver. While fetching the available `validating admissionWebhooks` we saw that there was an error trying to get Cert-manager's webhook. We deleted both webhooks and the cluster returned to its normal state.

The most likley cause was Cert-manager's webhook. We deleted both webhooks at the same time so we can not be entirely sure that it **actually** was cert-manager and not OPA's webhook that interfered. Looking at the logs from OPA did not suggest that there was anything strange happening.

### Lessons learned

If all kubernetes components are up and running it might be worth to take a look at and see what admission webhooks are present in the cluster to see if they are interfering cluster operations.