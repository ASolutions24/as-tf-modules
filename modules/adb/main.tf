terraform {
    required_providers {
      databricks = {
       #source = "databrickslabs/databricks"
       #version = "=0.5.9"
       source  = "databricks/databricks"
       version = "1.27.0"
    }
  }
}

locals {
  resource_group_name = format("rg-%s-%s", var.env, var.project)
}

# Create databricks workspace
resource "azurerm_databricks_workspace" "adb" {
  name                = format("adb-%s-%s", var.env, var.project)
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = "premium"
 #managed_resource_group_name = "${var.prefix}-DBW-managed-private-endpoint"

 ##To disable public access to workspace
 #public_network_access_enabled         = false 
 #network_security_group_rules_required = "NoAzureDatabricksRules"


  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.vnet_id
    public_subnet_name                                   = "public_subnet"
    private_subnet_name                                  = "private_subnet"
    public_subnet_network_security_group_association_id  = var.public_subnet_network_security_group_association_id
    private_subnet_network_security_group_association_id = var.private_subnet_network_security_group_association_id
  }
}

# Create Databricks Cluster
data "databricks_node_type" "smallest" {
  depends_on  = [ azurerm_databricks_workspace.adb ]
  local_disk  = true
  category    = "General Purpose"
}

data "databricks_spark_version" "latest" {
  depends_on = [ azurerm_databricks_workspace.adb ]
  latest = true
  long_term_support = true
}

# Grab secrets from azure key vault
data "azurerm_key_vault_secret" "databricksappclientid" {
  name         = "${var.secretsname["databricksappclientid"]}"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "databricksappsecret" {
  name         = "${var.secretsname["databricksappsecret"]}"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "tenantid" {
  name         = "${var.secretsname["tenantid"]}"
  key_vault_id = var.key_vault_id
}

# Create Databricks Scope
resource "databricks_secret_scope" "dbwscope" {
  depends_on = [ azurerm_databricks_workspace.adb ]
  name = var.dbwscope
  initial_manage_principal = "users"
  
  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }
}

resource "databricks_cluster" "shared_autoscaling" {
  depends_on = [ azurerm_databricks_workspace.adb, databricks_secret_scope.dbwscope ]
  cluster_name            = format("%s-%s-cluster", var.env, var.project)
  num_workers             = 1
  spark_version           = data.databricks_spark_version.latest.id
  #node_type_id           = data.databricks_node_type.smallest.id
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 20
  
  autoscale {
    min_workers = 1
    max_workers = 1
  }


  spark_conf = {

    "spark.hadoop.fs.azure.account.auth.type.${var.stgaccname}.dfs.core.windows.net": "OAuth", # Using local variable, value will show in adb cluster spark config
    "spark.hadoop.fs.azure.account.oauth.provider.type.${var.stgaccname}.dfs.core.windows.net": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "spark.hadoop.fs.azure.account.oauth2.client.id.${var.stgaccname}.dfs.core.windows.net": "{{secrets/devdbwkvscope/databricksappclientid}}", #This method will not display the actual value stored in key vault which is more secure
    "spark.hadoop.fs.azure.account.oauth2.client.secret.${var.stgaccname}.dfs.core.windows.net": "{{secrets/devdbwkvscope/databricksappsecret}}",
    #"spark.hadoop.fs.azure.account.oauth2.client.endpoint.stgaccadlsdevdata001.dfs.core.windows.net": "https://login.microsoftonline.com/007f5007-e452-411f-ad5a-09aebef34a20/oauth2/token"
    "spark.hadoop.fs.azure.account.oauth2.client.endpoint.${var.stgaccname}.dfs.core.windows.net": "https://login.microsoftonline.com/${data.azurerm_key_vault_secret.tenantid.value}/oauth2/token" #This method also will show the value in adb cluster spark config
  }


}

# resource "databricks_secret_scope" "kv" {
#   name = "keyvault-managed"

#   keyvault_metadata {
#     resource_id = var.key_vault_id
#     dns_name    = var.key_vault_uri
#   }
# }