variable "av_parser_external_ip" {
  description = "The LoadBalancer IP for the ArgoCD service."
  type        = string
  sensitive = true
} 

variable "go_bills_parser_external_ip" {
  description = "The LoadBalancer IP for the Go Bills API service."
  type        = string
  sensitive = true
}

variable "overlays_dir" {
  type      = string
  sensitive = false
}
