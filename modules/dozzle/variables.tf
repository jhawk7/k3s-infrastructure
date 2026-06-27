variable "dozzle_external_ip" {
  type      = string
  sensitive = true
}

variable "overlays_dir" {
  type      = string
  sensitive = false
}

variable "dozzle_remote_agents" {
  type      = string
  sensitive = true
}