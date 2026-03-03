variable "external_ip" {
  description = "The LoadBalancer IP for the InfluxDB service."
  type        = string
}

variable "overlays_dir" {
  description = "The overlays directory for kustomize patches."
  type        = string
}
