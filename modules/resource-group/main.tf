resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s-%s", var.env, var.project)
  location = var.location

  tags = {
    Source= var.source_code
    Owner = var.owner
    Client = var.org
    Project = var.project
  }
}