## Ansible playbooks for deploying Kubernetes

Individual playbooks:

- **deploy-kubernetes.yml** is an "all in one" playbook that simply includes the other. Run this to deploy kubernetes.
  - **initialize-master.yml** starts (the first) control plane node and installs a network provider.
  - **ha-control-plane.yml** adds additional control plane nodes
  - **join-cluster.yml** adds worker nodes to the cluster

### Variables

See `group_vars` for some common variables, especially cloud provider related variables can be found here.
Other variables can be included in the inventory file or passed to ansible when running the playbook.

The most notable variables are documented here:

- `kubeconfig_path`: The path to store the cluster-admin kubeconfig at.
- `control_plane_endpoint`: The IP of the internal loadbalancer when running HA control plane.
- `public_endpoint`: The IP of the public endpoint for the API server. This can be the FQDN of an external loadbalancer or the public IP of the master in a non-HA cluster.
- `cloud_provider`: Required for cloud provider integration. The name of the cloud provider (e.g. aws or openstack).
- `cloud_config`: The path to the `cloud.conf` file on the node if the cloud provider integration requires it. Most commonly `/etc/kubernetes/cloud.conf`.
- `cluster_name`: The name of the cluster in order to distinguish between different clusters.
