terraform {
  required_providers {
    tfe = "0.18.0"
  }
}

provider "tfe" {}

variable "organization" {
  type = string
}

variable "workspace_name" {
  type = string
}

resource "tfe_workspace" "workspace" {
  name         = var.workspace_name
  organization = var.organization
  // Local execution mode
  operations = false
}
