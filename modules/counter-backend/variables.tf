variable "external_ip" {
  type      = string
  sensitive = true
}

variable "overlays_dir" {
  type      = string
  sensitive = false
}

variable "docker_config_b64" {
  type      = string
  sensitive = true
}
