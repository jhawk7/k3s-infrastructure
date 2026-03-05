variable "external_ip" {
  sensitive = true
  type = string
}

variable influxdb_admin_user {
  type = string
  sensitive = true
}

variable "influxdb_admin_password" {
  sensitive = true
  type = string
}

variable "influxdb_bills_token" {
  type = string
  sensitive = true
}

variable "influxdb_proxmox_token" {
  type = string
  sensitive = true
}