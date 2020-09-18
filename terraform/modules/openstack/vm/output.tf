output "instance_ids" {
  description = "Instance to id mapping."

  value = {
    for instance in openstack_compute_instance_v2.instance :
    instance.name => instance.id
  }
}

output "floating_ips" {
  description = "List of floating ips."

  value = values(openstack_compute_floatingip_v2.fip)[*].address
}

output "instance_ips" {
  description = "The private (fixed) and floating (public) ip addresses per instance."

  value = {
    for key, instance in openstack_compute_instance_v2.instance :
    instance.name => {
      "private_ip" = openstack_networking_port_v2.port[key].all_fixed_ips.0,
      "public_ip"  = openstack_compute_floatingip_v2.fip[key].address
    }
  }
}
