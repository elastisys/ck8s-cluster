# Night manual

Make sure to also check the [troubleshooting docs](troubleshooting.md).

Before you start, record the current state of the cluster:
```
kubectl cluster-info dump > cluster-dump.json
```

The steps and subsections here are in order of severity, starting with mild actions that have minimal impact on the workload/cluster.

## Application problems

Try killing problematic pods to get fresh ones:
```shell
kubectl delete pods <name> -n <namespace>
```

### Helm charts

**Set up helm flags** to access the correct tiller:
```shell
# Service cluster
source scripts/helm-env.sh kube-system clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/service_cluster/kube-system/certs "helm"
# Workload cluster
source scripts/helm-env.sh kube-system clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/workload_cluster/kube-system/certs "helm"
# check that it works
helm list
```

**Roll back helm releases:**
```shell
# show current release(s)
helm list
# check the history of revisions
helm history <release>
# roll back to previous revision
helm rollback <release> 0
# roll back to specific revision
helm rollback <release> <revision>
```

**Backup current values:**
```shell
helm get values <release> > backup-values.yaml
```
If the above doesn't work, check at least the image tag(s) used:
```shell
kubectl -n <namespace> get deploy -o wide
```
If that is also impossible, check the manifests/chart templates to see what image tag was used or check the container registry for a suitable image to use.

**Delete helm chart:**
```shell
helm delete <release>
# Alternatively, if the release is in a bad state:
helm delete --purge <release>
```
Warning: the above will lead to downtime since the application is completely removed from the cluster.
Note that the second command will completely clear the revision history.

**Reinstall** by running a deploy script OR manually:
```shell
helm upgrade --install <release> <chart> --namespace <namespace> -f backup-values.yaml
# Example:
# helm upgrade --install app1 app-chart --namespace app-namespace -f backup-values.yaml
```
If you were unable to do a backup of the values, use the deploy script.

### Completely recreate a namespace

Note: before you do this, make sure to **backup current values** as described above.

Check the application specific documentation for each application.
In short you will have to delete the namespace (`kubectl delete namespace <namespace>`) and then re-initialize it for the troublesome application.
This will most likely require re-running the deploy script.

## Node problem

If a node is having problems, try adding new nodes (using terraform and RKE) and draining the problematic node.
```
kubectl drain <node-name> --ignore-daemonsets --delete-local-data
```
This should be enough to move almost everything from the node.
Only daemonsets will still run pods there.

To completely remove the node, you also have to remove it from the cluster and delete the virtual machine.
See the RKE [documentation](https://rancher.com/docs/rke/latest/en/managing-clusters/) for how to remove the node from the cluster.
Remember to also delete the virtual machine using terraform.
```
# remove the virtual machine from terraform code and then apply:
terraform apply
```
