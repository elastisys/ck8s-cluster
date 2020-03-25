# CK8S Configuration

## Elasticsearch

### Number of nodes

The number of Elasticsearch nodes is defined with `ES_NODE_COUNT` parameter.
By default, each shard has one additional replica, which means that in order to get a green cluster health, you will need to deploy an Elasticsearch cluster with at least two data nodes (one for the primary shards and one for the replica shards).

`ES_NODE_COUNT` >= 2

### Elasticsearch storage capacity

Each Elasticsearch node has associated storage.
The capacity of node storage is defined with `ES_STORAGE_SIZE` paramater.

In the **Exoscale** environment local storage is used for Elasticsearch nodes.
When hosts are provisioned, the Elasicsearch node file system is mounted in a file on the host.
The size of the file is defined with by the `es_local_storage_capacity_map_sc` parameter in `config.tfvars` file.
The values in `es_local_storage_capacity_map_sc` have to be equal to zero (if the Elasticsearch node should not run on the host) or greater than `ES_STORAGE_SIZE`.

for each `es_local_storage_capacity` in `es_local_storage_capacity_map_sc`:  
(`es_local_storage_capacity` > `ES_STORAGE_SIZE`) or (`es_local_storage_capacity` == 0 if the Elasticsearch node should not run on the host)

The number of host capable of running Elasticsearch nodes cannot be lower than `ES_NODE_COUNT`.

### Indecies groups and their retention limits

There are three groups of Elasticsearch indecies:

* **kubeaudit** - Kubernetes audit logs
* **kubernetes** - Logs from containers running within the cluster
* **other** - Misc logs from docker daemon

Each group has its own retention size limit defined using the following parameters:

* `KUBEAUDIT_RETENTION_SIZE`
* `KUBERNETES_RETENTION_SIZE`
* `OTHER_RETENTION_SIZE`

These size limits include both primary and replica shards.

The sum of all retention size limits has to be smaller than the total storage capacity of all Elasticsearch nodes.

(`KUBEAUDIT_RETENTION_SIZE` + `KUBERNETES_RETENTION_SIZE` +`OTHER_RETENTION_SIZE`) <= `ES_NODE_COUNT` * `ES_STORAGE_SIZE`
