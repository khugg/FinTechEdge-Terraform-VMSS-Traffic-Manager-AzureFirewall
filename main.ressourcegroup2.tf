# Define variables
variable "vmss2_desired_capacity" {
  type    = number
  default = 2
}

# Resource Group 2
resource "azurerm_resource_group" "rg0" {
  name     = "resource_group0"
  location = "canadacentral"
}

# Virtual Network 2
resource "azurerm_virtual_network" "vnet_2" {
  name                = "virtual_network2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Project"
  }
}

# Subnet 3(app)
resource "azurerm_subnet" "subnet_3" {
  name                 = "subnet_3"
  resource_group_name  = azurerm_resource_group.rg0.name
  virtual_network_name = azurerm_virtual_network.vnet_2.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Subnet 4(data)
resource "azurerm_subnet" "subnet_4" {
  name                 = "subnet_4"
  resource_group_name  = azurerm_resource_group.rg0.name
  virtual_network_name = azurerm_virtual_network.vnet_2.name
  address_prefixes     = ["10.0.2.0/24"]
}


# Network Security Group 3 (with RDP rule)
resource "azurerm_network_security_group" "nsg_3" {
  name                = "nsg_3"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*" # Allow from any IP. For security, restrict this.
    destination_address_prefix = "*"
  }
}

# Network Security Group 4 (with RDP rule)
resource "azurerm_network_security_group" "nsg_4" {
  name                = "nsg_4"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name

  security_rule {
    name                       = "Allow_RDP"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*" # Allow from any IP. For security, restrict this.
    destination_address_prefix = "*"
  }
}


# NSG Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_3_assoc" {
  subnet_id                 = azurerm_subnet.subnet_3.id
  network_security_group_id = azurerm_network_security_group.nsg_3.id
}


# NSG Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_4_assoc" {
  subnet_id                 = azurerm_subnet.subnet_4.id
  network_security_group_id = azurerm_network_security_group.nsg_4.id
}







# Public IP for VM
resource "azurerm_public_ip" "vm_public_ip2" {
  name                = "vm-public-ip2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Project"
  }
}




# Network Interface for VM
resource "azurerm_network_interface" "nic_3" {
  name                = "nic_3"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name

  ip_configuration {
    name                          = "ipconfig3"
    subnet_id                     = azurerm_subnet.subnet_3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip2.id
  }
}


resource "azurerm_network_interface" "nic_4" {
  name                = "nic_4"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name


ip_configuration {
    name                          = "ipconfig4"
    subnet_id                     = azurerm_subnet.subnet_4.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null
  }
  }



# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm_2" {
  name                  = "vm2"
  resource_group_name   = azurerm_resource_group.rg0.name
  location              = azurerm_resource_group.rg0.location
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = "P@55w0rd1234!"

  network_interface_ids = [azurerm_network_interface.nic_3.id]

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

  tags = {
    environment = "Project"
  }
}




# Load Balancer Public IP
resource "azurerm_public_ip" "lb_pip2" {
  name                = "lb_pip2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Project"
  }
}

# Load Balancer
resource "azurerm_lb" "my_load_balancer2" {
  name                = "my_load_balancer2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb_pip2.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool2" {
  loadbalancer_id = azurerm_lb.my_load_balancer2.id
  name            = "backend_pool2"
}

resource "azurerm_lb_rule" "lb_rule2" {
  name                              = "http_lb_rule2"
  loadbalancer_id                   = azurerm_lb.my_load_balancer2.id
  frontend_port                     = 80
  backend_port                      = 80
  protocol                          = "Tcp"
  frontend_ip_configuration_name    = "frontend"
}

resource "azurerm_lb_probe" "http_probe2" {
  name                = "http_probe2"
  loadbalancer_id     = azurerm_lb.my_load_balancer2.id
  protocol            = "Http"
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
  port                = 80
}

# VM Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "vmss_2" {
  name                 = "vmss_2"
  resource_group_name  = azurerm_resource_group.rg0.name
  location             = azurerm_resource_group.rg0.location
  sku                  = "Standard_F2"
  instances            = var.vmss_desired_capacity
  admin_password       = "P@55w0rd1234!"
  admin_username       = "adminuser"
  computer_name_prefix = "vm2"
 

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name="network"
    primary = true

    ip_configuration {
      name      = "ipconfig3"
      subnet_id = azurerm_subnet.subnet_3.id
  
  }
}
  }

# Autoscale Settings
resource "azurerm_monitor_autoscale_setting" "autoscale2" {
  name                = "autoscale2"
  resource_group_name = azurerm_resource_group.rg0.name
  location            = azurerm_resource_group.rg0.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss_2.id

  profile {
    name = "default"
    capacity {
      minimum = 1
      maximum = 10
      default = var.vmss_desired_capacity
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss_1.id
        statistic          = "Average"
        time_grain         = "PT5M"
        time_window        = "PT5M"
        operator           = "GreaterThan"
        threshold          = 70
        time_aggregation   = "Average"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }

}



resource "azurerm_traffic_manager_profile" "globalWebAppRouting2" {
  name                 = "globalWebAppRouting2"
   traffic_routing_method = "Priority"
  resource_group_name = azurerm_resource_group.rg0.name
   monitor_config {
    protocol             = "HTTP"
    port                 = 80
    path ="/"
    interval_in_seconds  = 30
    timeout_in_seconds   = 5
    tolerated_number_of_failures = 3
  }
  

  dns_config {
    relative_name = "globalWebAppRoutingprofile2"
    ttl           = 30
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "canadacentral" {
  name                 = "canadacentral"
  profile_id           = azurerm_traffic_manager_profile.globalWebAppRouting2.id
  always_serve_enabled = true
  weight               = 100
   target_resource_id   =  azurerm_windows_web_app.web_app2.id 
  }




resource "azurerm_service_plan" "service_plan2" {
  name                = "service_plan2"
  resource_group_name = azurerm_resource_group.rg0.name
  location            = azurerm_resource_group.rg0.location
  sku_name            = "P1v2"
  os_type             = "Windows"
  }





resource "azurerm_windows_web_app" "web_app2" {
  name                = "windows-web-app2"
  resource_group_name = azurerm_resource_group.rg0.name
  location            ="canadacentral"

  service_plan_id     = azurerm_service_plan.service_plan2.id

  site_config {}
}



resource "azurerm_storage_account" "mystorageaccountone2"{
  name                     = "vivihaccountone2"
  location                 = azurerm_resource_group.rg0.location
  resource_group_name      = azurerm_resource_group.rg0.name
  account_tier             = "Standard"
  account_replication_type = "GRS" 
  }

  
# Create a Recovery Services Vault
resource "azurerm_recovery_services_vault" "myRecoveryVault3" {
  name                = "myRecoveryVault3"
  location             = azurerm_resource_group.rg0.location
  resource_group_name  = azurerm_resource_group.rg0.name
  sku                  = "Standard"
  
}


# Create a Backup Policy for VMs
resource "azurerm_backup_policy_vm" "vm_policy2" {
  name                = "vm_backup_policy2"
  resource_group_name  = azurerm_resource_group.rg0.name
  recovery_vault_name = azurerm_recovery_services_vault.myRecoveryVault3.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 42
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 77
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}


# 1. Backup Vault
resource "azurerm_data_protection_backup_vault" "blobbackup2" {
  name                = "mybackupvault2"
  resource_group_name = azurerm_resource_group.rg0.name
  location           = "canadacentral"
  datastore_type     = "VaultStore"
  redundancy         = "GeoRedundant"

  identity {
    type = "SystemAssigned"
  }
}



resource "azurerm_role_assignment" "test" {
  scope                = azurerm_storage_account.mystorageaccountone2.id
  role_definition_name = "Storage Account Backup Contributor"

  principal_id         = azurerm_data_protection_backup_vault.blobbackup2.identity[0].principal_id
}



# 2. Backup Policy
resource "azurerm_data_protection_backup_policy_blob_storage" "blobstoragepolicy2" {
  name                = "backup-policy2"
  vault_id           = azurerm_data_protection_backup_vault.blobbackup2.id
  operational_default_retention_duration = "P30D"
  time_zone          = "UTC"
}


resource "azurerm_data_protection_backup_policy_blob_storage" "another" {
  name                = "another"
  vault_id           = azurerm_data_protection_backup_vault.blobbackup2.id
  operational_default_retention_duration = "P15D"
  time_zone          = "UTC"
}

# 3. Backup Instance
resource "azurerm_data_protection_backup_instance_blob_storage" "myblobbackupinstance2" {
  name               = "backup-instance2"
  vault_id          = azurerm_data_protection_backup_vault.blobbackup2.id
  location          = azurerm_resource_group.rg0.location
  backup_policy_id  = azurerm_data_protection_backup_policy_blob_storage.blobstoragepolicy2.id
  storage_account_id = azurerm_storage_account.mystorageaccountone2.id


  depends_on = [azurerm_role_assignment.test1]
}



#step 4

# Create a Subnet for the Firewall
resource "azurerm_subnet" "firewall_subnet2" {
  name                 = "AzureFirewallSubnet2"
  resource_group_name  = azurerm_resource_group.rg0.name
  virtual_network_name = azurerm_virtual_network.vnet_2.name
  address_prefixes     = ["10.0.4.0/24"] 
}

# Create a Public IP for the Firewall
resource "azurerm_public_ip" "firewall_ip2" {
  name                = "firewall-ip2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  allocation_method   = "Static"
}

# Create the Azure Firewall
resource "azurerm_firewall" "my-firewall2" {
  name                = "my-firewall2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  sku_name            = "AZFW_VNet" # Choose your desired SKU

  sku_tier = "Standard"

  # ... Add other rule collections (Application, NAT) as needed ...
}


#step 4 isn't finish, i should add something 








#step 5 

# Create a Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "my-log-analytics-workspace2" {
  name                = "my-log-analytics-workspace2"
  location            = azurerm_resource_group.rg0.location
  resource_group_name = azurerm_resource_group.rg0.name
  sku = "PerGB2018" # Choose the appropriate SKU
    retention_in_days   = 30
}

# Enable Diagnostics Settings for a Virtual Machine (Example)
resource "azurerm_monitor_diagnostic_setting" "vmss-diagnostics2" {
  name                 = "vmss-diagnostics2"
  target_resource_id    = azurerm_windows_virtual_machine_scale_set.vmss_2.id 
  log_analytics_workspace_id = azurerm_log_analytics_workspace.my-log-analytics-workspace2.id

  
  metric {
    category = "AllMetrics"
   }
}



# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics2" {
  name                       = "storage-diagnostics2"
  target_resource_id         = azurerm_storage_account.mystorageaccountone2.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.my-log-analytics-workspace2.id

 metric {
  category = "Transaction"
  }
 }


 # Diagnostic Settings for Network Interface
resource "azurerm_monitor_diagnostic_setting" "network_diagnostics2" {
  name                       = "network-diagnostics2"
  target_resource_id         = azurerm_network_interface.nic_3.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.my-log-analytics-workspace2.id
metric {
  category = "AllMetrics"
  }
 }

