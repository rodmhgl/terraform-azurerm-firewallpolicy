variable "name" {
  description = "The name of the Firewall Policy."
  type        = string
}

variable "location" {
  description = "The location/region where the Firewall Policy should be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Firewall Policy."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "created_by" = "rstewart"
    "purpose"    = "fwpolicy_testing"
  }
}
