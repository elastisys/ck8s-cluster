# Troubleshooting Kubernetes

https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/

## Cluster problems

Check cluster info and status of components:
```
kubectl cluster-info
kubectl get componentstatuses
```

Check nodes:
```
kubectl get nodes
kubectl describe node <name>
```

Check validating webhooks and API services:
```
kubectl get validatingwebhookconfigurations
kubectl get apiservices
```
The API server may time out or forbid requests if an API service or the service backing a validating webhook is down.

## Workload problems (pods)

List pods and check their status: `kubectl get pods --all-namespaces`. Are they all `Running`? (Jobs can be `Completed` also.)
Describe failed pods: `kubectl -n <namespace> describe pod <name>`.
Check logs for a pod: `kubectl -n <namespace> logs <name>`
Are pods missing? Check deployments and replicasets to see if they have trouble creating pods:
```
kubectl get deployment --all-namespaces
kubectl -n <namespace> describe deployment <name>
kubectl -n <namespace> describe replicaset <name>
```

Check statefulsets and daemonsets:
```
kubectl get statefulsets --all-namespaces
kubectl -n <namespace> describe statefulset <name>
kubectl get daemonsets --all-namespaces
kubectl -n <namespace> describe daemonset <name>
```

## Network problems

Check that services exist and have endpoints:
```
kubectl get svc --all-namespaces
kubectl -n <namespace> describe svc <name>
```

Check ingresses:
```
kubectl get ingress --all-namespaces
kubectl -n <namespace> describe ingress <name>
```

Make sure ingresses have the correct IP and the DNS is configured for them.

Check certificates:
```
kubectl get certificates --all-namespaces
kubectl -n <namespace> describe certificate <name>
```
Compare also with the secrets that are used to store the certificates:
```
kubectl -n <namespace> describe secret <name>
```

Check that the network plugin pods are up and running.

## Performance - resource starvation

Check resource usage in terminal for nodes and pods:
```
kubectl top nodes
kubectl top pods --all-namespaces
```

In Grafana, start from the cluster level and "drill down".
The dashboards "Kubernetes / Compute Resources / Cluster" and "Kubernetes / USE Method / Cluster" show cluster level metrics.
