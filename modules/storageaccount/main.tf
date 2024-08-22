locals {
  resource_group_name = format("rg-%s-%s", var.env, var.project)
}

locals {
  stgaccname = "${var.stgaccname}${var.env}${var.project}001"
}

# Create storage account
resource "azurerm_storage_account" "stacdata01" {
  name                     = local.stgaccname
  resource_group_name      = local.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  blob_properties {
    delete_retention_policy {
      days = 1
    }
    container_delete_retention_policy {
      days = 1
    }
  }
}

# Create containers for bronze, silver and gold layer
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.stacdata01.name
  container_access_type = "private"
}

output "azurerm_storage_container" {
  value = azurerm_storage_container.bronze.id
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.stacdata01.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.stacdata01.name
  container_access_type = "private"
}

resource "azurerm_private_dns_zone" "stg-dfs-dns" {
  depends_on = [ azurerm_storage_account.stacdata01 ]
  name = "privatelink.dfs.core.windows.net"
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet-link" {
  name = format("vnet-%s-%s-link",var.env, var.project)
  resource_group_name = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.stg-dfs-dns.name
  virtual_network_id = var.vnet_id
}

resource "azurerm_private_endpoint" "stacdata01-pe" {
  depends_on = [ azurerm_storage_account.stacdata01 ]
  name = "${local.stgaccname}-pe"
  resource_group_name = local.resource_group_name
  location = var.location
  subnet_id = var.private_link_subnet_id

    private_dns_zone_group {
      name = "private-stgacc-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.stg-dfs-dns.id]
    }
    
    private_service_connection {
      name = "stgacc-pe-connection"
      private_connection_resource_id = azurerm_storage_account.stacdata01.id
      is_manual_connection = false
      subresource_names = ["dfs"]
    }
}