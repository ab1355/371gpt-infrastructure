# main.tf
terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
      version = "~> 0.25.0"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "~> 1.49.0"
    }
  }
}

provider "ovh" {
  endpoint           = "ovh-us"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.us/v3"
  tenant_id   = var.os_tenant_id
  tenant_name = var.os_tenant_name
  user_name   = var.os_username
  password    = var.os_password
  region      = "US-EAST-VA"
}