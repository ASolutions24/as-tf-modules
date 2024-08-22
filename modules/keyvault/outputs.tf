output "kv_id" {
    value = azurerm_key_vault.adb_kv.id
}

output "kv_uri" {
  value = azurerm_key_vault.adb_kv.vault_uri
}

output "databricksappclientid" {
  value = azurerm_key_vault_secret.databricksappclientid.value
}

output "databricksappsecret" {
  value = azurerm_key_vault_secret.databricksappsecret.value
}

output "tenantid" {
  value = azurerm_key_vault_secret.tenantid.value
}