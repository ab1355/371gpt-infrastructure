# variables.tf
variable "ovh_application_key" {
  type = string
  sensitive = true
}

variable "ovh_application_secret" {
  type = string
  sensitive = true
}

variable "ovh_consumer_key" {
  type = string
  sensitive = true
}

variable "os_tenant_id" {
  type = string
}

variable "os_tenant_name" {
  type = string
}

variable "os_username" {
  type = string
}

variable "os_password" {
  type = string
  sensitive = true
}

variable "ssh_key_pair" {
  type = string
  description = "Name of the SSH key pair to use for instances"
  default = "your-keypair-name"
}