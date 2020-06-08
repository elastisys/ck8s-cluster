resource "openstack_networking_port_v2" "port" {
  for_each = toset(var.names)

  name       = "${var.prefix}-${each.value}-port"
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }

  security_group_ids = var.security_group_ids
  admin_state_up     = "true"
}

resource "openstack_compute_instance_v2" "instance" {
  for_each = toset(var.names)

  name = "${var.prefix}-${each.value}"

  image_id  = var.image_id
  flavor_id = var.name_flavor_map[each.value]
  key_pair  = var.key_pair

  network {
    port = openstack_networking_port_v2.port[each.value].id
  }

  scheduler_hints {
      group = var.server_group_id
   }
}

resource "openstack_compute_floatingip_v2" "fip" {
  for_each = toset(var.names)

  pool = var.external_network_name
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  for_each = toset(var.names)

  floating_ip = openstack_compute_floatingip_v2.fip[each.value].address
  instance_id = openstack_compute_instance_v2.instance[each.value].id
}
