# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

variable "labelPrefix" {
 type        = string
 default     = "daig"
 description = "this is the prefix for the label"
}
variable "region" {
 type        = string
 default     = "Canada Central"
 description = "the defined region"
}
variable "admin_username" {
 type        = string
 default     = "daig0104"
 description = "the username of admin"
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}

resource "azurerm_resource_group" "Lab5RG" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

resource "azurerm_public_ip" "publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.Lab5RG.name
  location            = azurerm_resource_group.Lab5RG.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_network" "labVN" {
  name                = "lab5-network"
  location            = azurerm_resource_group.Lab5RG.location
  resource_group_name = azurerm_resource_group.Lab5RG.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.Lab5RG.name
  virtual_network_name = azurerm_virtual_network.labVN.name
  address_prefixes     = ["10.0.1.0/24"]  # Subnet within the VNet
  #network_security_group_id = azurerm_network_security_group.example_nsg.id
}
