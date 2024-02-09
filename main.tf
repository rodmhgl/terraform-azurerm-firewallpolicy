locals {
  rule_collection = {
    example-fwpolicy-rcg = {
      name     = "example-fwpolicy-rcg"
      priority = 500
      application_rule_collection = {
        app_rule_collection_one = {
          name     = "app_rule_collection1"
          priority = 500
          action   = "Deny"
          app_rule_collection1_rule1 = {
            protocols = {
              Http = {
                port = 80
              }
              Https = {
                port = 443
              }
            }
            source_addresses  = ["10.0.0.1"]
            destination_fqdns = ["*.microsoft.com"]
          }
        }
      }
      network_rule_collection = {
        name     = "network_rule_collection1"
        priority = 400
        action   = "Deny"
        rule = {
          network_rule_collection1_rule1 = {
            protocols             = ["TCP", "UDP"]
            source_addresses      = ["10.0.0.1"]
            destination_addresses = ["192.168.1.1", "192.168.1.2"]
            destination_ports     = ["80", "1000-2000"]
          }
        }
      }
      nat_rule_collection = {
        nat_rule_collection1 = {
          priority = 300
          action   = "Dnat"
          rule = {
            nat_rule_collection1_rule1 = {
              protocols           = ["TCP", "UDP"]
              source_addresses    = ["10.0.0.1", "10.0.0.2"]
              destination_address = "192.168.1.1"
              destination_ports   = ["80"]
              translated_address  = "192.168.0.1"
              translated_port     = "8080"
            }
          }
        }
    } }
  }
  rule_collections      = yamlencode(local.rule_collection)
  yaml_rule_collections = yamldecode(file("${path.module}/rule_collections.yml"))
}

# resource "local_file" "yaml" {
#   filename = "./rule_collections.yml"
#   content  = local.rule_collections
# }

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "this" {
  name = azurerm_resource_group.this.name
}

resource "azurerm_firewall_policy" "parent" {
  name                     = var.name
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  for_each = local.yaml_rule_collections.rule_collection_groups

  name               = each.key
  firewall_policy_id = azurerm_firewall_policy.parent.id
  priority           = each.value.priority

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.key
      action   = application_rule_collection.value.action
      priority = application_rule_collection.value.priority

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name                  = rule.key
          description           = try(rule.value.description, null)
          source_addresses      = try(rule.value.source_addresses, null)
          source_ip_groups      = try(rule.value.source_ip_groups, null)
          destination_addresses = try(rule.value.destination_addresses, null)
          destination_urls      = try(rule.value.destination_urls, null)
          destination_fqdn_tags = try(rule.value.destination_fqdn_tags, null)
          destination_fqdns     = try(rule.value.destination_fqdns, null)
          terminate_tls         = try(rule.value.terminate_tls, null)
          web_categories        = try(rule.value.web_categories, null)

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.key
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.key
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action
      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.key
          description           = try(rule.value.description, null)
          protocols             = rule.value.protocols
          destination_ports     = rule.value.destination_ports
          source_addresses      = try(rule.value.source_addresses, null)
          source_ip_groups      = try(rule.value.source_ip_groups, null)
          destination_addresses = try(rule.value.destination_addresses, null)
          destination_ip_groups = try(rule.value.destination_ip_groups, null)
          destination_fqdns     = try(rule.value.destination_fqdns, null)
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = each.value.nat_rule_collections
    content {
      name     = nat_rule_collection.key
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action
      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.key
          description         = try(rule.value.description, null)
          protocols           = rule.value.protocols
          source_addresses    = try(rule.value.source_addresses, null)
          source_ip_groups    = try(rule.value.source_ip_groups, null)
          destination_address = try(rule.value.destination_address, null)
          destination_ports   = try(rule.value.destination_ports, null)
          translated_address  = try(rule.value.translated_address, null)
          translated_fqdn     = try(rule.value.translated_fqdn, null)
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

# resource "azurerm_firewall_policy" "child" {
#   name                     = "child-fwp"
#   resource_group_name      = data.azurerm_resource_group.this.name
#   location                 = data.azurerm_resource_group.this.location
#   base_policy_id           = azurerm_firewall_policy.parent.id
#   sku                      = "Standard"
#   threat_intelligence_mode = "Alert"
# }

# output "rule_collections" {
#   value = local.rule_collections
# }

# output "yaml_rule_collections" {
#   value = local.yaml_rule_collections
# }
