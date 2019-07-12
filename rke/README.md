###Quickstart

* Download the `rke` binary <https://github.com/rancher/rke/releases/>.
* Rename the binary to `rke` for simplicity and, preferably, add it to your path.
* Run `rke up --config <RKE_CLUSTER-CONF>.yaml` to create the Kubernetes cluster.
* To access the cluster use the generate kubeconfig `kube_config_<RKE_CLUSTER-CONF>.yaml`
* See <https://rancher.com/docs/rke/latest/en/example-yamls/> for cluster configurations.
* Run `rke remove --config <RKE_CLUSTER-CONF>.yaml` to remove the Kubernetes cluster.


###Deploy customer and system services cluster
* First run `terraform apply` for the each cluster
* Run `./deploy-ss.sh` to start the system services cluster.
* Run `./deploy-c.sh` after the system services cluster has started to deploy the customer cluster.
