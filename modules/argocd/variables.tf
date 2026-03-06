variable "argocd_external_ip" {
  description = "The LoadBalancer IP for the ArgoCD service."
  type        = string
  sensitive = true
} 

variable "rollouts_external_ip" {
  description = "The LoadBalancer IP for the Argo Rollouts service."
  type        = string
  sensitive = true
}