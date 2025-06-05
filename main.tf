terraform {
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "3.0.0"
      }
    }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "task_rg" {
  name      = "rg-vm-test-centralindia"
  location  = local.location
} 

resource "azurerm_storage_account" "task_storage" {
  name = "taskstoragetf"
  resource_group_name = var.resource_group_name
  location = local.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  depends_on = [ azurerm_resource_group.task_rg ]
}

resource "azurerm_storage_container" "task_container" {
  name = "container-researchupload-test-centralidia"
  storage_account_name  = "taskstoragetf"
  container_access_type = "private"
  depends_on            = [ 
                           azurerm_storage_account.task_storage
                           ]
}

resource "azurerm_storage_blob" "task_blob" {
  name = "blob-research-test-centralindia"
  storage_account_name   = "taskstoragetf"
  storage_container_name = "container-researchupload-test-centralidia"
  type                   = "Block"
  source                 = "summary.txt"
  depends_on             = [
                             azurerm_storage_container.task_container,
                             azurerm_storage_account.task_storage
                            ]
}

resource "azurerm_virtual_network" "task_vnet" {
  name                = "vnet-vm-test-centralindia"
  location            = local.location
  resource_group_name = var.resource_group_name  
  address_space       = ["10.0.0.0/16"]
  depends_on          = [
                          azurerm_resource_group.task_rg
                         ]
}

resource "azurerm_subnet" "task_subnet" {
  name                 = "vmsubner-vm-test-centralindia"
  resource_group_name  = var.resource_group_name
  virtual_network_name = "vnet-vm-test-centralindia"
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [
                           azurerm_virtual_network.task_vnet
                          ]
}

resource "azurerm_network_interface" "task_nic" {
  name                = "nic-web-test-centralindia"
  location            = local.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "taskipconfig"
    subnet_id                     = azurerm_subnet.task_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on                      = [ 
                                      azurerm_resource_group.task_rg
                                     ]
}

resource "azurerm_availability_set" "task_avset" {
    name = "avset-web-test-centralindia"
    resource_group_name = var.resource_group_name
    location = local.location
    platform_fault_domain_count = 3
    platform_update_domain_count = 3

  
}
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vm-web-test-ci"
  resource_group_name = var.resource_group_name
  location            = local.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.task_nic.id,
  ]
  availability_set_id = azurerm_availability_set.task_avset.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_availability_set.task_avset ]
}

resource "azurerm_managed_disk" "task_manageddisk" {
  name                 = "disk-vm-test-centralindia"
  resource_group_name  = var.resource_group_name
  location             = local.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         =  126  
}

resource "azurerm_virtual_machine_data_disk_attachment" "task_diskattach" {
  virtual_machine_id  = azurerm_windows_virtual_machine.vm.id
  managed_disk_id     = azurerm_managed_disk.task_manageddisk.id
  lun                 = "0"
  caching             = "ReadWrite"
  depends_on = [ azurerm_windows_virtual_machine.vm, azurerm_managed_disk.task_manageddisk ]
}

resource "azurerm_network_security_group" "task_nsgname" {
  name = "nsg-vm-test-centralindia"
  location = local.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "task_inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  } 
}

resource "azurerm_subnet_network_security_group_association" "task_nsg_associate" {
  subnet_id = azurerm_subnet.task_subnet.id
  network_security_group_id = azurerm_network_security_group.task_nsgname.id
  depends_on = [ azurerm_network_security_group.task_nsgname ]
}

resource "azurerm_key_vault" "task_keyvault" {
  name = "kv-app-test-centralindia"
  location                    = local.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
    ]

    storage_permissions = [
      "Get",
    ]
  } 
}

resource "azurerm_key_vault_secret" "task_kvsc" {
  name = "kvsc-tfapp-test-centralindia"
  value = var.kv_secret_value
  key_vault_id = azurerm_key_vault.task_keyvault.id
  depends_on = [ azurerm_key_vault.task_keyvault ] 
}

resource "azurerm_dns_zone" "task_dnszone" {
  name                = "kloudtech.net"
  resource_group_name = var.resource_group_name
}