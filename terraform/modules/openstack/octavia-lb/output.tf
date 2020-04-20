
output "floating_ips" {
  description = "List of floating ips."

  value = values(openstack_networking_floatingip_v2.loadbalancer_lb_fip)[*].address
}

output "instance_ips" {
  description = "The floating (public) ip addresses per instance."

  value = {
    for key, name in var.names :
    name => {
      "public_ip" = openstack_networking_floatingip_v2.loadbalancer_lb_fip[key].address
    }
  }
}