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
  subscription_id ="ed19ccdf-7b4a-4666-8948-3923639ec896"
  tenant_id="69a24b27-7e8e-4b16-99b1-99134658842e"
  client_id="5355660b-7628-43b1-9048-7e52434ce778"


 }
    
  
    



