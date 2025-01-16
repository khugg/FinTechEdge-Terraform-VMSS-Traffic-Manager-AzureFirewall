    # 1. Specify the version of the AzureRM Provider to use

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=4.14.0"
    }
  }
}


# 2.configure Microsoft Azure Provider


provider "azurerm" {
  features {}
  subscription_id =""
  tenant_id=""
  client_id=""


 }
    
  
    



