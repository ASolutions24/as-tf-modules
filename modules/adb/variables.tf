variable "env" {

}
variable "project" {
  
}

variable "location" {
    description = "Location in which resource needs to be spinned up"
}

variable "vnet_id" {
  description = "Vnet ID for DNS integration"
}

variable "stgaccname" {
  
}

variable "dbwscope" {
  type    = string
  default = "devdbwkvscope"
}

variable "secretsname" {
    type = map
    default = {
        "databricksappsecret" = "databricksappsecret"
        "databricksappclientid" = "databricksappclientid"
        "tenantid" = "tenantid"
    }
}

variable "public_subnet_network_security_group_association_id" {
}

variable "private_subnet_network_security_group_association_id" {
}

variable "key_vault_id" {
  
}

variable "key_vault_uri" {
  
}