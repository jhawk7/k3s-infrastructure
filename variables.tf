variable "counter_producer_external_ip" {
  type = string
  sensitive = true
}

variable "smb_source" {
  type = string
  sensitive = true
}

variable "metallb_ip_pool" {
  type      = string
  sensitive = true
}