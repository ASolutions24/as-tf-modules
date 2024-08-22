locals {
  resource_group_name = format("rg-%s-%s", var.env, var.project)
}


resource "azurerm_public_ip" "public-ip" {
  name                = format("public-ip-%s-%s", var.env, var.project)
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "standard-fw-policy" {
  name                = format("standard-fw-policy-%s-%s", var.env, var.project)
  location            = var.location
  resource_group_name = local.resource_group_name
  sku = "Standard"
}

resource "azurerm_firewall" "adb-firewall" {
  name                = format("firewall-%s-%s", var.env, var.project)
  location            = var.location
  resource_group_name = local.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.standard-fw-policy.id

  ip_configuration {
    name                 = "adb_configuration"
    subnet_id            = var.fw_subnet_id
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }

  depends_on = [ azurerm_public_ip.public-ip ]
}

####################################### Application Rule Collection ######################################
resource "azurerm_firewall_policy_rule_collection_group" "adb_application_rules" {
  name                = "adb-control-plane-app-rules"
  firewall_policy_id = azurerm_firewall_policy.standard-fw-policy.id
  priority = 300

      application_rule_collection {
        name     = "DefaultApplicationRuleCollection"
        action   = "Allow"
        priority = 200

        rule {
        name = "Metastore"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["consolidated-australiaeast-prod-metastore.mysql.database.azure.com", "consolidated-australiaeast-prod-metastore-addl-1.mysql.database.azure.com"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "Artifact Blob storage primary"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.blob.core.windows.net"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "System tables storage"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["ucstprdauste.dfs.core.windows.net"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "Log Blob storage"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["dblogprodausteast.blob.core.windows.net"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "Event Hub endpoint"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["prod-australiaeast-observabilityeventhubs.servicebus.windows.net"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "ubuntu-update"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.ubuntu.com"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "snap-packages"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.snapcraft.io"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "terracotta"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.terracotta.org"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "cloudflare"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.cloudflare.com"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

        rule {
        name = "sts-aws"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["sts.amazonaws.com"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "tunnel"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["tunnel.australiaeast.azuredatabricks.net"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "google dns"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["dns.google.com"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "monitor"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["global.handler.control.monitor.azure.com", "australiaeast.handler.control.monitor.azure.com"]

        protocols {
        type = "Http"
        port = 80
        }
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "md-hdd"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.blob.storage.azure.net"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "cdn"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["cdn.fwupd.org"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "packages"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["packages.microsoft.com"]
        protocols {
          port = "443"
          type = "Https"
        }
      }

          rule {
        name = "DBFS"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["*.dfs.core.windows.net"]
        protocols {
          port = "443"
          type = "Https"
        }  
      }

        rule {
        name = "AzureAD-Authentication"
        source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
        destination_fqdns = ["login.microsoftonline.com"]
        protocols {
          port = "443"
          type = "Https"
        }  
      }
    }
}

resource "azurerm_firewall_policy_rule_collection_group" "adb_network_rules" {
  depends_on = [ azurerm_firewall_policy.standard-fw-policy ]
  name                = "adb-control-plane-network-rules"
  firewall_policy_id = azurerm_firewall_policy.standard-fw-policy.id
  priority            = 200
      
    network_rule_collection {
      name     = "DefaultNetworkRuleCollection"
      action   = "Allow"
      priority = 200  
        rule {
            name = "adb-webapp"
            source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
            destination_ports = ["443"]
            destination_addresses = ["13.75.218.172/32"]
            protocols = ["Any"]
        }

        rule {
            name = "extended-infrastructure"
            source_addresses = ["10.10.1.0/26","10.10.1.64/26"]
            destination_ports = ["443"]
            destination_addresses = ["20.53.145.128/28"]
            protocols = ["Any"]
        }
    }
}

#################################################################################################################


resource "azurerm_route_table" "adb-route-table" {
  name                          = "adb-route-table"
  location                      = var.location
  resource_group_name           = local.resource_group_name

  route {
      name = "adb-webapp"
      address_prefix = "13.75.218.172/32"
      next_hop_type = "Internet"
  }
  route {
      name = "control-Plane-NAT"
      address_prefix = "13.70.105.50/32"
      next_hop_type = "Internet"
  }
  route {
      name = "Extended-infrastructure"
      address_prefix = "20.53.145.128/28"
      next_hop_type = "Internet"
  }

  route {
    name           = "to-firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.adb-firewall.ip_configuration[0].private_ip_address
  }
  

}

resource "azurerm_subnet_route_table_association" "adb-pubic-rt-assocation" {
  subnet_id      = var.rt_public_subnet
  route_table_id = azurerm_route_table.adb-route-table.id
}

resource "azurerm_subnet_route_table_association" "adb-private-rt-assocation" {
  subnet_id      = var.rt_private_subnet
  route_table_id = azurerm_route_table.adb-route-table.id
}