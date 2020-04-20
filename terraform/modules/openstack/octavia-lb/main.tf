locals {
  instance_ips = [for key, value in var.worker_ips : { instance_name = key, instance_ip = value.private_ip }]
  octavia_matrix = [
    for pair in setproduct(var.names, local.instance_ips) : {
      octavia_name  = pair[0]
      instance_name = pair[1].instance_name
      instance_ip   = pair[1].instance_ip
    }
  ]
}

resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  for_each      = var.names
  name          = each.value
  vip_subnet_id = var.subnet_id
}

resource "openstack_lb_listener_v2" "loadbalancer_80" {
  for_each        = var.names
  name            = "${each.value}-80"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer[each.value].id
  default_pool_id = openstack_lb_pool_v2.loadbalancer_http[each.value].id
}

resource "openstack_lb_listener_v2" "loadbalancer_443" {
  for_each        = var.names
  name            = "${each.value}-443"
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer[each.value].id
  default_pool_id = openstack_lb_pool_v2.loadbalancer_https[each.value].id
}

resource "openstack_lb_pool_v2" "loadbalancer_http" {
  for_each        = var.names
  name            = "${each.value}-80"
  lb_method       = "ROUND_ROBIN"
  protocol        = "HTTP"
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer[each.value].id
}

resource "openstack_lb_pool_v2" "loadbalancer_https" {
  for_each        = var.names
  name            = "${each.value}-443"
  lb_method       = "ROUND_ROBIN"
  protocol        = "HTTPS"
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer[each.value].id
}


resource "openstack_lb_member_v2" "loadbalancer_80" {
  for_each = {
    for pair in local.octavia_matrix : "${pair.octavia_name}.${pair.instance_name}" => pair
  }

  address       = each.value.instance_ip
  pool_id       = openstack_lb_pool_v2.loadbalancer_http[each.value.octavia_name].id
  protocol_port = 80
  subnet_id     = var.subnet_id
}

resource "openstack_lb_member_v2" "loadbalancer_443" {
  for_each = {
    for pair in local.octavia_matrix : "${pair.octavia_name}.${pair.instance_name}" => pair
  }

  address       = each.value.instance_ip
  pool_id       = openstack_lb_pool_v2.loadbalancer_https[each.value.octavia_name].id
  protocol_port = 443
  subnet_id     = var.subnet_id
}

resource "openstack_networking_floatingip_v2" "loadbalancer_lb_fip" {
  for_each = var.names
  pool     = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "loadbalancer_lb_fip_assoc" {
  for_each    = var.names
  floating_ip = openstack_networking_floatingip_v2.loadbalancer_lb_fip[each.value].address
  port_id     = openstack_lb_loadbalancer_v2.loadbalancer[each.value].vip_port_id
  depends_on = [
    openstack_lb_loadbalancer_v2.loadbalancer,
    openstack_lb_listener_v2.loadbalancer_80,
    openstack_lb_listener_v2.loadbalancer_443
  ]
}

# Health Monitor

resource "openstack_lb_monitor_v2" "loadbalancer_80" {
  for_each       = var.names
  name           = "${each.value}-80"
  pool_id        = openstack_lb_pool_v2.loadbalancer_http[each.value].id
  type           = "HTTP"
  url_path       = "/healthz"
  expected_codes = "200"
  delay          = 20
  timeout        = 10
  max_retries    = 5
}

resource "openstack_lb_monitor_v2" "loadbalancer_443" {
  for_each       = var.names
  name           = "${each.value}-443"
  pool_id        = openstack_lb_pool_v2.loadbalancer_https[each.value].id
  type           = "HTTPS"
  url_path       = "/healthz"
  expected_codes = "200"
  delay          = 20
  timeout        = 10
  max_retries    = 5
}