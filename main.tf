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
  location = "${var.region}"
}

resource "azurerm_public_ip" "publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.Lab5RG.name
  location            = azurerm_resource_group.Lab5RG.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "lab5NSG" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.Lab5RG.location
  resource_group_name = azurerm_resource_group.Lab5RG.name

  security_rule {
    name                       = "SSH-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "HTTP-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "lab5NIC" {
  name                = "lab5-nic"
  location            = azurerm_resource_group.Lab5RG.location
  resource_group_name = azurerm_resource_group.Lab5RG.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}
resource "azurerm_network_interface_security_group_association" "attach_nsg" {
  network_interface_id = azurerm_network_interface.lab5NIC.id
  network_security_group_id = azurerm_network_security_group.lab5NSG.id

} 

resource "azurerm_virtual_machine" "webServer" {
  name                  = "WebVM"
  location              = azurerm_resource_group.Lab5RG.location
  resource_group_name   = azurerm_resource_group.Lab5RG.name
  network_interface_ids = [azurerm_network_interface.lab5NIC.id]
  vm_size               = "Standard_B1s"   

  storage_os_disk {
    name              = "webServerDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type           = "Linux"  # Use "Windows" if it's a Windows server
  }

  os_profile {
    computer_name  = "webServerVM"
    admin_username = "${var.admin_username}"      
    admin_password = "password1234!"  
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

