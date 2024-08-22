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

variable "private_link_subnet_id" {
    description = "ID of Private link Subnet"
  
}
variable "stacdata01_id" {
  
}

variable "secretsname" {
    type = map
    default = {
        "databricksappsecret" = "databricksappsecret"
        "databricksappclientid" = "databricksappclientid"
        "tenantid" = "tenantid"
    }
}