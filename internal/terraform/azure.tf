resource "azurerm_resource_group" "solutions-architecture" {
  name     = "solutions-architecture"
  location = "Central US"
}

resource "azurerm_storage_account" "solutions-architecture" {
  name                     = "solutions-architecture"
  resource_group_name      = azurerm_resource_group.solutions-architecture.name
  location                 = azurerm_resource_group.solutions-architecture.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "ccm" {
  name                  = "ccm"
  storage_account_name  = azurerm_storage_account.solutions-architecture.name
  container_access_type = "private"
}