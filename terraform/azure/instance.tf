resource random_string "password" {
  length      = 16
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
}

resource azurerm_linux_virtual_machine "linux_machine" {
  admin_username                  = "zs-terraform-iac-scanning-linux"
  admin_password                  = random_string.password.result
  location                        = var.location
  name                            = "zs-terraform-iac-scanning-linux"
  network_interface_ids           = [azurerm_network_interface.ni_linux.id]
  resource_group_name             = azurerm_resource_group.example.name
  size                            = "Standard_F2"
  disable_password_authentication = false
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = merge({
    zs-terraform-iac-scanning = true
    environment               = var.environment
    }, {
    git_file             = "terraform/azure/instance.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  })
}

resource azurerm_windows_virtual_machine "windows_machine" {
  admin_password        = random_string.password.result
  admin_username        = "tg-${var.environment}"
  location              = var.location
  name                  = "tg-win"
  network_interface_ids = [azurerm_network_interface.ni_win.id]
  resource_group_name   = azurerm_resource_group.example.name
  size                  = "Standard_F2"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  tags = merge({
    zs-terraform-iac-scanning = true
    environment               = var.environment
    }, {
    git_file             = "terraform/azure/instance.tf"
    git_org              = "zscaler-bd-sa"
    git_repo             = "zs-terraform-iac-scanning"
  })
}