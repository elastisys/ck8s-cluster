output "instance_ids" {
  value = "${openstack_compute_instance_v2.instance.*.id}"
}

output "floating_ips" {
  value = "${openstack_compute_floatingip_v2.fip.*.address}"
}

output "fixed_ips" {
  value = "${openstack_networking_port_v2.port.*.all_fixed_ips.0}"
}
