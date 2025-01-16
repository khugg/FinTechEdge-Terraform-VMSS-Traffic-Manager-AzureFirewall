# Define variables
variable "vmss_desired_capacity" {
  type    = number
  default = 2
}

# Resource Group 1
resource "azurerm_resource_group" "rg" {
  name     = "resource_group"
  location = "westus2"
}

# Virtual Network 1
resource "azurerm_virtual_network" "vnet_1" {
  name                = "virtual_network1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Project"
  }
}

# Subnet 1(app)
resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet_1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet 2(data)
resource "azurerm_subnet" "subnet_2" {
  name                 = "subnet_2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  address_prefixes     = ["10.0.2.0/24"]
}





# Network Security Group 1 (with RDP rule)
resource "azurerm_network_security_group" "nsg_1" {
  name                = "nsg_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

# Network Security Group 2 (with RDP rule)
resource "azurerm_network_security_group" "nsg_2" {
  name                = "nsg_2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
resource "azurerm_subnet_network_security_group_association" "nsg_1_assoc" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.nsg_1.id
}


# NSG Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_2_assoc" {
  subnet_id                 = azurerm_subnet.subnet_2.id
  network_security_group_id = azurerm_network_security_group.nsg_2.id
}



# Public IP for VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Project"
  }
}




# Network Interface for VM
resource "azurerm_network_interface" "nic_1" {
  name                = "nic_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}


resource "azurerm_network_interface" "nic_2" {
  name                = "nic_2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.subnet_2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null
  }
  }



# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm_1" {
  name                  = "vm1"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = "P@55w0rd1234!"

  network_interface_ids = [azurerm_network_interface.nic_1.id]

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
resource "azurerm_public_ip" "lb_pip" {
  name                = "lb_pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Project"
  }
}

# Load Balancer
resource "azurerm_lb" "load_balancer" {
  name                = "my_load_balancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "backend_pool"
}

resource "azurerm_lb_rule" "lb_rule" {
  name                              = "http_lb_rule"
  loadbalancer_id                   = azurerm_lb.load_balancer.id
  frontend_port                     = 80
  backend_port                      = 80
  protocol                          = "Tcp"
  frontend_ip_configuration_name    = "frontend"
}

resource "azurerm_lb_probe" "http_probe" {
  name                = "http_probe"
  loadbalancer_id     = azurerm_lb.load_balancer.id
  protocol            = "Http"
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
  port                = 80
}

# VM Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "vmss_1" {
  name                 = "vmss_1"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = "Standard_F2"
  instances            = var.vmss_desired_capacity
  admin_password       = "P@55w0rd1234!"
  admin_username       = "adminuser"
  computer_name_prefix = "vm1"
 

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
      name      = "ipconfig"
      subnet_id = azurerm_subnet.subnet_1.id
  
  }
}
  }

# Autoscale Settings
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss_1.id

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



resource "azurerm_traffic_manager_profile" "globalWebAppRoutingprofile" {
  name                 = "globalWebAppRoutingprofile"
   traffic_routing_method = "Priority"
  resource_group_name = azurerm_resource_group.rg.name
   monitor_config {
    protocol             = "HTTP"
    port                 = 80
    path ="/"
    interval_in_seconds  = 30
    timeout_in_seconds   = 5
    tolerated_number_of_failures = 3
  }
  

  dns_config {
    relative_name = "globalWebAppRouting1profile"
    ttl           = 30
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "westus2" {
  name                 = "westus2"
  profile_id           = azurerm_traffic_manager_profile.globalWebAppRoutingprofile.id
  always_serve_enabled = true
  weight               = 100
   target_resource_id   =  azurerm_windows_web_app.web_app.id 
  }




resource "azurerm_service_plan" "service_plan" {
  name                = "service_plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "P1v2"
  os_type             = "Windows"
  }





resource "azurerm_windows_web_app" "web_app" {
  name                = "windows-web-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            ="westus2"
  service_plan_id     = azurerm_service_plan.service_plan.id

  site_config {}
}

#step 3

resource "azurerm_storage_account" "storageaccountone"{
  name                     = "vivihaccountone"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS" 
  }

  
# Create a Recovery Services Vault
resource "azurerm_recovery_services_vault" "myRecoveryVault" {
  name                = "myRecoveryVault2"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  sku                  = "Standard"
  
}


# Create a Backup Policy for VMs
resource "azurerm_backup_policy_vm" "vm_policy" {
  name                = "vm_backup_policy"
  resource_group_name  = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.myRecoveryVault.name

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
resource "azurerm_data_protection_backup_vault" "blobbackup" {
  name                = "mybackupvault"
  resource_group_name = azurerm_resource_group.rg.name
  location           = "westus2"
  datastore_type     = "VaultStore"
  redundancy         = "GeoRedundant"

  identity {
    type = "SystemAssigned"
  }
}



resource "azurerm_role_assignment" "test1" {
  scope                = azurerm_storage_account.storageaccountone.id
  role_definition_name = "Storage Account Backup Contributor"
  principal_id         = azurerm_data_protection_backup_vault.blobbackup.identity[0].principal_id
}



# 2. Backup Policy
resource "azurerm_data_protection_backup_policy_blob_storage" "blobstoragepolicy" {
  name                = "backup-policy"
  vault_id           = azurerm_data_protection_backup_vault.blobbackup.id
  operational_default_retention_duration = "P30D"
  time_zone          = "UTC"
}


resource "azurerm_data_protection_backup_policy_blob_storage" "another1" {
  name                = "another1"
  vault_id           = azurerm_data_protection_backup_vault.blobbackup.id
  operational_default_retention_duration = "P15D"
  time_zone          = "UTC"
}

# 3. Backup Instance
resource "azurerm_data_protection_backup_instance_blob_storage" "myblobbackupinstance" {
  name               = "backup-instance"
  vault_id          = azurerm_data_protection_backup_vault.blobbackup.id
  location          = azurerm_resource_group.rg.location
  backup_policy_id  = azurerm_data_protection_backup_policy_blob_storage.blobstoragepolicy.id
  storage_account_id = azurerm_storage_account.storageaccountone.id


  depends_on = [azurerm_role_assignment.test1]
}
#step 4

# Create a Subnet for the Firewall
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  address_prefixes     = ["10.0.4.0/24"] 
}

# Create a Public IP for the Firewall
resource "azurerm_public_ip" "firewall_ip" {
  name                = "firewall-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create the Azure Firewall
resource "azurerm_firewall" "my-firewall" {
  name                = "my-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet" # Choose your desired SKU

  sku_tier = "Standard"

  # ... Add other rule collections (Application, NAT) as needed ...
}


  
/*
   #Define Allowed Locations
resource "azurerm_policy_definition" "allowed_location" {
  name                = "allowed-location"
  display_name        = "Allow Resources Only in Specific Locations"
  description         = "Restricts resource creation to specific locations."
  mode                = "All"
  policy_type         = "Custom"
    policy_rule = <<POLICY
  {
    "if": {
      "field": "location",
      "notIn": ["westus2", "canadacentral"]
    },
    "then": {
      "effect": "deny"
    }
  }
  POLICY
  }
*/

/*# Define Tag Requirement
resource "azurerm_policy_definition" "require_tag" {
  name                = "RequireEnvironmentTagAssignment"
  display_name        = "Require 'Environment' Tag"
  description         = "This policy requires resources to have the 'Environment' tag."
  policy_type         = "Custom"
  mode                = "All"
  policy_rule = <<POLICY
  {
    "if": {
      "not": {
        "field": "tags['Environment']"
      }
    },
    "then": {
      "effect": "deny"
    }
  }
  POLICY
}/*

/*resource "azurerm_policy_definition" "restrict_vm_sku" {
  name                = "restrict-vm-sku"
  display_name        = "Restrict VM SKUs"
  description         = "Limits VM SKUs to a predefined list."
  policy_type         = "BuiltIn"
  mode                = "All"
  policy_rule = <<POLICY
  {
    "if": {
      "field": "sku.name",
      "notIn": [
        "Standard_D2s_v3",
        "Standard_D4s_v3"
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
  POLICY
}/*


# Declare the azurerm_resource_group data source
data "azurerm_resource_group" "rg" {
  name = "resource_group"  # Replace with your actual resource group name
}

# Assign Allowed Locations Policy
/*data "azurerm_policy_assignment" "policy_assignment" {
  name     = "policy_assignment"
  scope_id = data.azurerm_resource_group.rg.id
}

output "id" {
  value = data.azurerm_policy_assignment.policy_assignment.id
}*/


/*data "azurerm_policy_assignment" "policy_assignment" {
  name  = "ASC Default (subscription: ed19ccdf-7b4a-4666-8948-3923639ec896)"
  scope_id = "/subscriptions/ed19ccdf-7b4a-4666-8948-3923639ec896"
}/*


# Assign Require Tag Policy
/*resource "azurerm_policy_assignment" "require_tag_assignment" {
  name                 = "require-tag-assignment"
  scope                = "/subscriptions/<ed19ccdf-7b4a-4666-8948-3923639ec896>" 
  display_name        = "Require 'Environment' Tag Assignment"
  policy_definition_id = azurerm_policy_definition.require_tag.id
}*/


/*data "azurerm_policy_assignment" "require_tag_assignment" {
  name     = "require_tag_assignment"
  scope_id = data.azurerm_resource_group.rg.id
}*/

# Assign VM SKU Restriction Policy
/*resource "azurerm_policy_assignment" "restrict_vm_sku_assignment" {
  name                 = "restrict-vm-sku-assignment"
  scope                = "/subscriptions/<ed19ccdf-7b4a-4666-8948-3923639ec896>" 
  display_name        = "Restrict VM SKUs Assignment"
  policy_definition_id = azurerm_policy_definition.restrict_vm_sku.id
  parameters = jsonencode({
    "allowedSkus": [
      "Standard_D2s_v3",
      "Standard_D4s_v3"
    ]
  })
}*/

/*data "azurerm_policy_assignment" "restrict_vm_sku_assignment" {
  name     = "restrict_vm_sku_assignment"
  scope_id = data.azurerm_resource_group.rg.id
}*/

 

 /*# Get Management Group data
data "azurerm_management_group" "management-group-name" {
  display_name = "your-management-group-name"
}*/

/*resource "azurerm_management_group_policy_assignment" "allowed_locations_assignment" {
  name                 = "allowed-locations-assignment"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  display_name         = "Allow Resources Only in Specific Locations Assignment"
  management_group_id  = "your-management-group-id"  # Add your management group ID here
  
  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "value": [
      "westus2",
      "canadacentral"
    ]
  }
}
PARAMETERS
}*/

/*# If using subscription scope instead:
resource "azurerm_subscription_policy_assignment" "allowed_locations_assignment" {
  name                 = "allowed-locations-assignment"
  subscription_id      = "/subscriptions/ed19ccdf-7b4a-4666-8948-3923639ec896"
  policy_definition_id = azurerm_policy_definition.allowed_location.id
  display_name         = "Allow Resources Only in Specific Locations Assignment"
  
  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "value": [
      "westus2",
      "canadacentral"
    ]
  }
}
PARAMETERS
}*/

# create  a blue print 




#step 5 

# Create a Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log-analytics-workspace" {
  name                = "log-analytics-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018" # Choose the appropriate SKU
    retention_in_days   = 30
}

# Enable Diagnostics Settings for a Virtual Machine (Example)
resource "azurerm_monitor_diagnostic_setting" "diagnostics1" {
  name                 = "diagnostics1"
  target_resource_id    = azurerm_windows_virtual_machine_scale_set.vmss_1.id 
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-analytics-workspace.id

  
  metric {
    category = "AllMetrics"
   }
}



# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostic" {
  name                       = "storage-diagnostic"
  target_resource_id         = azurerm_storage_account.storageaccountone.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-analytics-workspace.id

 metric {
  category = "Transaction"
  }
 }


 # Diagnostic Settings for Network Interface
resource "azurerm_monitor_diagnostic_setting" "network_diagnostic" {
  name                       = "network_diagnostic"
  target_resource_id         = azurerm_network_interface.nic_1.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-analytics-workspace.id
metric {
  category = "AllMetrics"
  }
 }


resource "azurerm_monitor_metric_alert" "CPUUsageAlert" {
  name                = "CPUUsageAlert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_virtual_machine_scale_set.vmss_1.id ]
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = " Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    skip_metric_validation = true
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}

resource "azurerm_monitor_metric_alert" "diskspaceAlert" {
  name                = "diskspaceAlert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_virtual_machine_scale_set.vmss_1.id ]
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = " Microsoft.Compute/virtualMachineScaleSetss"
    metric_name      = "diskspace"
    skip_metric_validation = true
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}

resource "azurerm_monitor_metric_alert" "networklatencyAlert" {
  name                = "networklatencyAlert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_virtual_machine_scale_set.vmss_1.id ]
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = " Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "network latency"
    skip_metric_validation = true
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}


# Create an Action Group
resource "azurerm_monitor_action_group" "ResourceHealthAlerts" {
  name                 = "ResourceHealthAlerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ResHealth"

  email_receiver {
    name                  = "AdminEmailReceiver"
    email_address         = "vivianeTchani@Mydomain2025.onmicrosoft.com"
    use_common_alert_schema = true
  }
    }

    resource "azurerm_application_insights" "test-appinsights" {
  name                = "test-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

output "instrumentation_key" {
  value = azurerm_application_insights.test-appinsights.instrumentation_key
     sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.test-appinsights.app_id
}


#step 6



resource "azurerm_automation_account" "automation_account" {
  name                = "my-automation-account"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  tags = {
    environment = "development"
  }
}




resource "azurerm_automation_runbook" "health_check" {
  name                    = "health-check"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name

  log_verbose             = true
  log_progress            = true
  description             = "Runbook to perform daily health checks."

  publish_content_link {
    uri = "https://raw.githubusercontent.com/khugg/FinTechEdge-Terraform-VMSS-Traffic-Manager-AzureFirewall/refs/heads/main/health_check.ps1"
  }

  runbook_type = "PowerShell"
}

resource "azurerm_automation_runbook" "vm_start_stop" {
  name                    = "vm-start-stop"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook to start/stop VMs for cost savings."
  publish_content_link {
    uri = "https://raw.githubusercontent.com/khugg/FinTechEdge-Terraform-VMSS-Traffic-Manager-AzureFirewall/refs/heads/main/health_check.ps1"
  }
  runbook_type            = "PowerShellWorkflow"
}

resource "azurerm_automation_schedule" "health_schedule" {
  name                    = "health-schedule"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Week"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2025-01-20T00:05:00Z"
  description             = "Runbook for health checks in the East region."
  week_days               = ["Friday"]
}

resource "azurerm_automation_schedule" "start_stop_schedule" {
  name                    = "start-stop-schedule"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Week"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2025-01-20T02:05:00Z"
  description             = "Daily schedule for VM start/stop runbook."
   week_days               = ["Friday"]
}



resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget"
  resource_group_id = azurerm_resource_group.rg.id

  amount     = 1000
  time_grain = "Monthly"

  time_period {
    start_date = "2025-01-01T00:00:00Z"
    end_date   = "2025-07-05T00:00:00Z"
  }

  notification {
  enabled        = true
    threshold      = 90.0
    operator       = "EqualTo"
    threshold_type = "Forecasted"
    contact_groups = [
      azurerm_monitor_action_group.ResourceHealthAlerts.id,]
  }
}







