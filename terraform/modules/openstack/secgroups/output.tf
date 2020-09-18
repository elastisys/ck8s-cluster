output "cluster_secgroup" {
  value = openstack_networking_secgroup_v2.cluster.id
}

output "master_secgroup" {
  value = openstack_networking_secgroup_v2.master.id
}

output "worker_secgroup" {
  value = openstack_networking_secgroup_v2.worker.id
}
