locals {

  lb_name = var.prefix

  # Flatten loadbalancer_targets to get a list of all individual members.
  members = flatten([
    for name, pool in var.loadbalancer_targets : [
      for key, value in pool.target_ips : {
        key           = name
        port          = pool.port
        protocol      = pool.protocol
        instance_name = key
        instance_ip   = value.private_ip
      }
    ]
  ])

  # Create a map with unique keys for all pool members.
  # The key will be <loadbalancer-name>.<instance-name>.<protocol>, e.g.
  # "loadbalancer-0.worker-0.http".
  pool_members = {
    for member in local.members : "${local.lb_name}.${member.instance_name}.${member.protocol}" => {
      protocol    = member.protocol
      port        = member.port
      instance_ip = member.instance_ip
      pool_name   = "${local.lb_name}.${member.key}"
    }
  }

  # Create a map with unique keys for all loadbalancer pools.
  # The key will be <loadbalancer-name>.<loadbalancer_target.key>, e.g.
  # "loadbalancer-0.http" or "loadbalancer-0.https".
  # This can be used directly with for_each.
  loadbalancer_pools = {
    for key, value in var.loadbalancer_targets : "${local.lb_name}.${key}" => {
      target = value
    }
  }
}

resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
  name               = var.prefix
  vip_subnet_id      = var.subnet_id
  security_group_ids = var.security_group_ids

}

resource "openstack_lb_pool_v2" "loadbalancer_pool" {
  for_each        = local.loadbalancer_pools
  name            = each.key
  lb_method       = "ROUND_ROBIN"
  protocol        = each.value.target.protocol
  loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
}

resource "openstack_lb_listener_v2" "loadbalancer_listener" {
  for_each            = local.loadbalancer_pools
  name                = each.key
  protocol            = each.value.target.protocol
  protocol_port       = each.value.target.port
  loadbalancer_id     = openstack_lb_loadbalancer_v2.loadbalancer.id
  default_pool_id     = openstack_lb_pool_v2.loadbalancer_pool[each.key].id
  allowed_cidrs       = each.value.target.allowed_cidrs
  timeout_client_data = each.value.target.timeout_client_data
}

resource "openstack_lb_member_v2" "pool_member" {
  for_each = local.pool_members
  pool_id  = openstack_lb_pool_v2.loadbalancer_pool[each.value.pool_name].id

  address       = each.value.instance_ip
  protocol_port = each.value.port
  subnet_id     = var.subnet_id
}

resource "openstack_networking_floatingip_v2" "loadbalancer_lb_fip" {
  pool        = var.external_network_name
  description = "IP for LB ${local.lb_name}"
}

resource "openstack_networking_floatingip_associate_v2" "loadbalancer_lb_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.loadbalancer_lb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.loadbalancer.vip_port_id
  depends_on = [
    openstack_lb_loadbalancer_v2.loadbalancer,
    openstack_lb_listener_v2.loadbalancer_listener
  ]
}

# Health Monitor

resource "openstack_lb_monitor_v2" "loadbalancer_monitor" {
  for_each       = local.loadbalancer_pools
  name           = each.key
  pool_id        = openstack_lb_pool_v2.loadbalancer_pool[each.key].id
  type           = each.value.target.protocol
  url_path       = each.value.target.health_path != "ignore" ? each.value.target.health_path : null
  expected_codes = each.value.target.health_codes != "ignore" ? each.value.target.health_codes : null
  delay          = each.value.target.health_delay
  timeout        = each.value.target.health_timeout
  max_retries    = each.value.target.health_max_retries
}
