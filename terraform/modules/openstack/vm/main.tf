data "openstack_images_image_v2" "image" {
  for_each = var.machines

  name        = each.value.image
  most_recent = true
}

resource "openstack_networking_port_v2" "port" {
  for_each = var.machines

  name       = "${var.prefix}-${each.key}-port"
  network_id = var.network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }

  security_group_ids = var.security_group_ids
  admin_state_up     = "true"
}

resource "openstack_compute_instance_v2" "instance" {
  for_each = var.machines

  name = "${var.prefix}-${each.key}"

  image_id  = data.openstack_images_image_v2.image[each.key].id
  flavor_id = each.value.size
  key_pair  = var.key_pair

  network {
    port = openstack_networking_port_v2.port[each.key].id
  }

  scheduler_hints {
    group = var.server_group_id
  }
}

resource "openstack_compute_floatingip_v2" "fip" {
  for_each = var.machines

  pool = var.external_network_name
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  for_each = var.machines

  floating_ip = openstack_compute_floatingip_v2.fip[each.key].address
  instance_id = openstack_compute_instance_v2.instance[each.key].id
}
