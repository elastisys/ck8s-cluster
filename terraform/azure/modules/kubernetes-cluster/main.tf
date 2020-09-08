#################################################
##
## General
##

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = [var.private_network_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_network_cidr]
}

data "azurerm_image" "base_os" {
  name                = var.compute_instance_image
  resource_group_name = "ck8s-base-os-image"
}

#################################################
##
## Master
##

resource "azurerm_public_ip" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  name                = "${var.prefix}-${each.key}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# This is needed since the public IPs don't get assiciated before nics are attached
data "azurerm_public_ip" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  name                = azurerm_public_ip.master[each.key].name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_virtual_machine.master]
}

resource "azurerm_network_interface" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  name                = "${var.prefix}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-ip-config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  network_interface_id      = azurerm_network_interface.master[each.key].id
  network_security_group_id = azurerm_network_security_group.master.id
}

resource "azurerm_availability_set" "master" {
  name                = "${var.prefix}-master"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_machine" "master" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "master"
  }

  name = "${var.prefix}-${each.key}"

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.master[each.key].id]
  availability_set_id   = azurerm_availability_set.master.id
  vm_size               = each.value.size

  # Delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.base_os.id
  }

  storage_os_disk {
    name          = "${var.prefix}-${each.key}-os-disk-1"
    caching       = "ReadWrite"
    disk_size_gb  = 50
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.prefix}-${each.key}"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = trimspace(file(pathexpand(var.ssh_pub_key)))
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }

  tags = {
    node_type = "master"
  }
}

resource "azurerm_network_security_group" "master" {
  name                = "${var.prefix}-master-sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "${var.prefix}-api-server-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefixes    = var.api_server_whitelist
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}-master-ssh-rule"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.public_ingress_cidr_whitelist
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "master_lb" {
  name                = "${var.prefix}-master-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_lb" "master_lb" {
  name                = "${var.prefix}-master-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "${var.prefix}-master-lb-ip"
    public_ip_address_id = azurerm_public_ip.master_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "master_lb" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.master_lb.id
  name                = "${var.prefix}-master-lb-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "master_lb" {
  for_each = azurerm_network_interface.master

  network_interface_id    = azurerm_network_interface.master[each.key].id
  ip_configuration_name   = "${var.prefix}-ip-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.master_lb.id
}

resource "azurerm_lb_probe" "master_lb" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.master_lb.id
  name                = "${var.prefix}-api-server"
  protocol            = "Tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "master_lb" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.master_lb.id
  name                           = "${var.prefix}-api-server"
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.master_lb.id
  probe_id                       = azurerm_lb_probe.master_lb.id
  frontend_ip_configuration_name = "${var.prefix}-master-lb-ip"
}

# resource "azurerm_lb_outbound_rule" "master_lb" {
#   resource_group_name     = azurerm_resource_group.main.name
#   loadbalancer_id         = azurerm_lb.master_lb.id
#   name                    = "OutboundRule"
#   protocol                = "Tcp"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.master_lb.id

#   frontend_ip_configuration {
#     name = "${var.prefix}-master-lb-ip"
#   }
# }

#################################################
##
## Worker
##

resource "azurerm_public_ip" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  name                = "${var.prefix}-${each.key}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# This is needed since the public IPs don't get assiciated before nics are attached
data "azurerm_public_ip" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  name                = azurerm_public_ip.worker[each.key].name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_virtual_machine.worker]
}

resource "azurerm_network_interface" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  name                = "${var.prefix}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-ip-config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  network_interface_id      = azurerm_network_interface.worker[each.key].id
  network_security_group_id = azurerm_network_security_group.worker.id
}


resource "azurerm_virtual_machine" "worker" {
  for_each = {
    for name, machine in var.machines :
    name => machine
    if machine.node_type == "worker"
  }

  name = "${var.prefix}-${each.key}"

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.worker[each.key].id]
  vm_size               = each.value.size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.base_os.id
  }

  storage_os_disk {
    name          = "${var.prefix}-${each.key}-os-disk-1"
    caching       = "ReadWrite"
    disk_size_gb  = 50
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.prefix}-${each.key}"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = trimspace(file(pathexpand(var.ssh_pub_key)))
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }

  tags = {
    node_type = "worker"
  }
}

resource "azurerm_network_security_group" "worker" {
  name                = "${var.prefix}-worker-sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "${var.prefix}-http-s-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}-master-ssh-rule"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.public_ingress_cidr_whitelist
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.prefix}-worker-nodeport-rule"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefixes    = var.nodeport_whitelist
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "worker_lb" {
  name                = "${var.prefix}-worker-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "worker_lb" {
  name                = "${var.prefix}-worker-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-worker-lb-ip"
    public_ip_address_id = azurerm_public_ip.worker_lb.id
  }
}

#################################################
##
## DNS
##

resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_suffix
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_dns_a_record" "example" {
  for_each = toset(var.dns_list)

  name                = "${each.value}.${var.dns_prefix}"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_public_ip.worker_lb.ip_address]
}
