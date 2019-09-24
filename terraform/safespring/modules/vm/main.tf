resource "openstack_networking_port_v2" "port" {
  count = var.instance_count

  name = "${var.instance_name}-port-${count.index}"

  network_id = "${var.network_id}"

  fixed_ip {
    subnet_id = "${var.subnet_id}"
  }

  security_group_ids = var.security_group_ids

  admin_state_up = "true"
}

resource "openstack_compute_instance_v2" "instance" {
  count = var.instance_count

  name = "${var.instance_name}-${count.index}"

  image_id  = "${var.image_id}"
  flavor_id = "${var.flavor_id}"
  key_pair  = "${var.key_pair}"

  network {
    port = "${element(openstack_networking_port_v2.port.*.id, count.index)}"
  }
}

resource "openstack_compute_floatingip_v2" "fip" {
  count = var.instance_count

  pool = "public-v4"
}

resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  count = var.instance_count

  floating_ip = "${element(
    openstack_compute_floatingip_v2.fip.*.address,
    count.index
  )}"

  instance_id = "${element(
    openstack_compute_instance_v2.instance.*.id,
    count.index
  )}"
}
