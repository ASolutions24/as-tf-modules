locals {
  resource_group_name = format("rg-%s-%s", var.env, var.project)
}

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "azuread_service_principal" "azuredatabricks" {
  display_name = "AzureDatabricks"
}

# Create Key vault
resource "azurerm_key_vault" "adb_kv" {
  name                        = "kv${var.env}${var.project}"
  location                    = var.location
  resource_group_name         = local.resource_group_name
  enable_rbac_authorization   = false
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # Access policy principal account
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["Get", "Create", "Delete", "List", "Restore", "Recover", "UnwrapKey", "WrapKey", "Purge", "Encrypt", "Decrypt", "Sign", "Verify", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
    secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
    storage_permissions = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]

  }

  # Access policy for AzureDatabricks Account
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_service_principal.azuredatabricks.object_id
    
    secret_permissions = ["Get", "List"]
  }

  sku_name = "standard"
}


resource "azurerm_private_dns_zone" "kv-dns" {
  depends_on = [ azurerm_key_vault.adb_kv ]
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "db-dns-link" {
    name = format("db-dns-%s-%s-link", var.env, var.project)
    resource_group_name          = local.resource_group_name
    private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
    virtual_network_id = var.vnet_id
  
}

resource "azurerm_private_endpoint" "kv-pe" {
  depends_on = [ azurerm_key_vault.adb_kv ]
  name = format("kv-%s-%s-pe", var.env, var.project)
  resource_group_name          = local.resource_group_name
  location                     = var.location
  subnet_id = var.private_link_subnet_id

    private_dns_zone_group {
    name                 = "private-kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv-dns.id]
  }

  private_service_connection {
    name = "kv-pe-connection"
    private_connection_resource_id = azurerm_key_vault.adb_kv.id
    is_manual_connection = false
    subresource_names = ["vault"]
  }
}

# Create Application
resource "azuread_application" "databricksapp" {
  display_name = "svcprdatabricks${var.env}${var.project}"
  owners       = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"
}
# Create Service Principal
resource "azuread_service_principal" "databricksapp" {
  application_id               = azuread_application.databricksapp.application_id
  #client_id                    = azuread_application.databricksapp.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  feature_tags {
    enterprise = true
    gallery    = true
  }
}
resource "time_rotating" "two_years" {
  rotation_days = 720
}

# Create secret for App
resource "azuread_application_password" "databricksapp" {
  depends_on = [ azurerm_key_vault.adb_kv ]
  display_name         = "databricksapp App Password"
  application_object_id = azuread_application.databricksapp.object_id
  #application_id = azuread_application.databricksapp.object_id
  
  rotate_when_changed = {
    rotation = time_rotating.two_years.id
  }
}

# Assign role to service principal
resource "azurerm_role_assignment" "databricksapp" {
  scope                = var.stacdata01_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.databricksapp.id
}


# Store secret, clientid and tenantid in key vault
resource "azurerm_key_vault_secret" "databricksappsecret" {
  name         = "${var.secretsname["databricksappsecret"]}"
  value        = azuread_application_password.databricksapp.value
  key_vault_id = azurerm_key_vault.adb_kv.id
}

resource "azurerm_key_vault_secret" "databricksappclientid" {
  name         = "${var.secretsname["databricksappclientid"]}"
  value        = azuread_application.databricksapp.application_id
  key_vault_id = azurerm_key_vault.adb_kv.id
}

resource "azurerm_key_vault_secret" "tenantid" {
  name         = "${var.secretsname["tenantid"]}"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.adb_kv.id
}