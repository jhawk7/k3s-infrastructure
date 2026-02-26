variable "nfs_server" {
  type      = string
  sensitive = true
}

variable "overlays_dir" {
  type      = string
  sensitive = false
}