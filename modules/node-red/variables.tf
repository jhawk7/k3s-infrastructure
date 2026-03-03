variable "external_ip" {
  description = "The LoadBalancer IP for the Node-RED service."
  type        = string
}

variable "overlays_dir" {
  description = "The overlays directory for kustomize patches."
  type        = string
}
