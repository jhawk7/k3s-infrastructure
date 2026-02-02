
variable "overlays_dir" {
  type      = string
  sensitive = false
}

variable "metallb_ip_pool" {
  type      = string
  sensitive = true
}