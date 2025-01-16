Phase 1 : Azure 104 

FinTechEdge-Terraform-VMSS-Traffic-Manager-AzureFirewall



## Table of Contents
- [Introduction](#introduction)
- [Tools Installation](#toolsinstallation)
- [Environments](#environments)




## Introduction

The Microsoft Azure Administrator involves the configuration, management, monitoring, and troubleshooting of Azure resources and services to ensure the effective functioning of cloud infrastructure within an organization.

## Tools Installation


1.Terraform

-	Download Terraform from the official website: Terraform Downloads.
-	Add the executable to your PATH.
-	Check the installation with terraform --version

2.Azure CLI

-	Download and install Azure CLI
-	Sign in to Azure: with az login
-	Check the installation with az --version

3.Install an IDE like Visual Studio Code with the Terraform extension for a better development experience.


## Environments

1.	Configuring environments

a.Creating an Azure Service User (Core Service)Terraform uses a Core Service to interact with Azure:az ad sp create-for-rbac --name "your main service name" --role="Contributor" --scopes="/subscriptions/<subscription_id>"Copy the information provided:• AppID• Password• Tenant ID4.2 Initializing Terraform variablesCreate a terraform.tfvars file:subscription_id="your subscription_id"client_id="your client_id"client_secret= "your Client_secret"tenant_id = "your tenant_id"
