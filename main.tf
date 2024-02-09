locals {   
  yaml_rule_collections = yamldecode(file("${path.module}/rule_collections.yml"))
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_firewall_policy" "parent" {
  name                     = var.name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
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
