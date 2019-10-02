# Service cluster outputs
output "vault_master_ip_addresses" {
  value = "${module.vault_cluster.master_ip_addresses}"
}

output "vault_master_count" {
  value = "${var.vault_master_count}"
}

output "vault_nfs_ip_address" {
  value = "${module.vault_cluster.nfs_ip_address}"
}

output "vault_dns_name" {
  value = "${module.vault_cluster.dns_record_name}"
}
