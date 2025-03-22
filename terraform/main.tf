resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}-network"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "internal" {
  name = "${var.prefix}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
  sku = "Basic"
}

# resource "azurerm_network_security_group" "nsg" {
#   name = "${var.prefix}-nsg"
#   resource_group_name = azurerm_resource_group.rg.name
#   location = azurerm_resource_group.rg.location

#   security_rule {
#     name = "AllowSSH"
#     priority = 1001
#     direction = "Inbound"
#     access = "Allow"
#     protocol = "Tcp"
#     source_port_range = "*"
#     destination_port_range = "22"
#     source_address_prefix = "*"
#     destination_address_prefix = "*"
#   }
# }

resource "azurerm_network_interface" "nic" {
  name = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  ip_configuration {
    name = "${var.prefix}-nic-configuration"
    subnet_id = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address = "10.0.1.5"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# resource "azurerm_network_interface_security_group_association" "nsg_association" {
#   network_interface_id = azurerm_network_interface.nic.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }

resource "azurerm_linux_virtual_machine" "vm" {
  name = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_A1_v2"
  admin_username = "yfrezzato"
  # admin_password = "Yfrezzaty-01"
  # disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  source_image_reference {
    publisher = "canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }

  admin_ssh_key {
    username = "yfrezzato"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "ls -la /tmp",
  #   ]

  #   connection {
  #     host = self.public_ip_address
  #     user = self.admin_username
  #     password = self.admin_password
  #   }
  # }
}

resource "azurerm_container_registry" "acr" {
  name = "${var.prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Basic"
  admin_enabled = true
  # georeplications {
  #   location = "North Europe"
  #   zone_redundancy_enabled = true
  #   tags = {}
  # }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name = "${var.prefix}-aks"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "${var.prefix}-aks"

  default_node_pool {
    name = "default"
    node_count = 1
    vm_size = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Development"
  }

  role_based_access_control_enabled = true
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "AcrPush"
  scope = azurerm_container_registry.acr.id
}

resource "kubernetes_storage_class" "azure-sc" {
  metadata {
    name = "azure-sc"
  }
  storage_provisioner = "kubernetes.io/azurefile"
  reclaim_policy = "Retain"
  volume_binding_mode = "Immediate"
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name = "azurefile-pvc"
    namespace = "default"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "azurefile"
  }
}