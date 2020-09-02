output "master_ip_addresses" {
  value = {
    for key, instance in azurerm_virtual_machine.master :
    instance.name => {
      "private_ip" = azurerm_network_interface.master_nics[key].private_ip_address
      "public_ip"  = lookup(data.azurerm_public_ip.master_pips_data, key, { "ip_address" : "" }).ip_address
    }
  }
}

output "worker_ip_addresses" {
  value = {
    for key, instance in azurerm_virtual_machine.worker :
    instance.name => {
      "private_ip" = azurerm_network_interface.worker_nics[key].private_ip_address
      "public_ip"  = lookup(data.azurerm_public_ip.worker_pips_data, key, { "ip_address" : "" }).ip_address
    }
  }
}

output "cluster_private_network_cidr" {
  value = var.private_network_cidr
}

output "dns_record_name" {
  value = [
    for dns_record in azurerm_dns_a_record.example :
    dns_record.fqdn
  ]
}

output "dns_suffix" {
  value = var.dns_suffix
}

output "ingress_controller_lb_ip_address" {
  value = azurerm_public_ip.worker_lb_pip.ip_address
}

output "control_plane_lb_ip_address" {
  value = azurerm_public_ip.master_lb_pip.ip_address
}
