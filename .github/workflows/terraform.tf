provider "azurerm" {
  version = "=2.4.0"

  subscription_id = "XXX...."
  client_id       = "XXX...."
  client_secret   = "XXX...."
  tenant_id       = "XXX...."
  features {
  }
}

# Create a resource group
resource "azurerm_resource_group" "MYRGMonoVM" {
  name     = "RGMonoVM"
  location = "West Europe"

  tags = {
    environment = "test"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "MyVnet" {
  name                = "My-network"
  address_space       = ["192.168.0.0/16"]
  resource_group_name = "${azurerm_resource_group.MYRGMonoVM.name}"
  location            = "${azurerm_resource_group.MYRGMonoVM.location}"

  tags = {
    environment = "test"
  }
}

resource "azurerm_subnet" "mySubnet" {
  name                 = "my-Subnet"
  address_prefix       = "192.168.1.0/24"
  resource_group_name  = "${azurerm_resource_group.MYRGMonoVM.name}"
  virtual_network_name = "${azurerm_virtual_network.MyVnet.name}"
}

# Créer un Network Security Group 
resource "azurerm_network_security_group" "myFirstNSG" {
  name                = "testNSG"
  location            = "west europe"
  resource_group_name = "${azurerm_resource_group.MYRGMonoVM.name}"

  # security_rule {
  #   name                       = "SSH"
  #   priority                   = 1001
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "test"
  }
}

# Create a network interface
resource "azurerm_network_interface" "myFirstNIC" {
  name                = "test-NIC"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.MYRGMonoVM.name}"

  #network_security_group_id = "${azurerm_network_security_group.myFirstNSG.id}"

  ip_configuration {
    name                          = "test-NIC-Config"
    subnet_id                     = "${azurerm_subnet.mySubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myPubIP.id}"
  }

  tags = {
    environment = "test"
  }
}

# Create an Public IP
resource "azurerm_public_ip" "myPubIP" {
  name                = "my-PublicIP"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.MYRGMonoVM.name}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "test"
  }
}

# Create a virtual machine within the resource group
resource "azurerm_virtual_machine" "MYVMAZ" {
  name                  = "VMAZ"
  location              = "${azurerm_resource_group.MYRGMonoVM.location}"
  resource_group_name   = "${azurerm_resource_group.MYRGMonoVM.name}"
  network_interface_ids = ["${azurerm_network_interface.myFirstNIC.id}"]
  vm_size               = "Standard_A1_V2"
  
  #delete_os_disk_on_termination = true
  #delete_data_disks_on_termination = true
  # this is a demo instance, so we can delete all data on termination
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  storage_os_disk {
    name              = "MyOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "Server 2016"
    admin_username = "jeanadmin"
    admin_password = "dgfasf809AD31@"
  }

  os_profile_windows_config {
    provision_vm_agent        = "true"
    enable_automatic_upgrades = "true"
    winrm {
      protocol = "http"
    }
  }
  tags = {
    environment = "test"
  }
}

