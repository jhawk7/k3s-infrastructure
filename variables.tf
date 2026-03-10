variable "counter_producer_external_ip" {
  type = string
  sensitive = true
}

variable "smb_source" {
  type = string
  sensitive = true
}

variable "nfs_server" {
  type = string
  sensitive = true
}

variable "metallb_ip_pool" {
  type      = string
  sensitive = true
}

variable "mqtt_external_ip" {
  type      = string
  sensitive = true  
}

variable "prom_external_ip" {
  type      = string
  sensitive = true  
}

variable "node5_ip" {
  type      = string
  sensitive = true
}

variable "node6_ip" {
  type      = string
  sensitive = true
}

variable "vnode_ip" {
  type      = string
  sensitive = true
}

variable "vnas_ip" {
  type      = string
  sensitive = true
}

variable "portainer_agent_external_ip" {
  type      = string
  sensitive = true  
}

variable "influxdb_external_ip" {
  type      = string
  sensitive = true  
}

variable "influxdb_admin_user" {
  type = string
  sensitive = true
}

variable "influxdb_admin_password" {
  type = string
  sensitive = true
}

variable "grafana_external_ip" {
  type      = string
  sensitive = true  
}

variable "grafana_influxdb_bills_token" {
  type = string
  sensitive = true
}

variable "grafana_influxdb_proxmox_token" {
  type = string
  sensitive = true
}

variable "argocd_external_ip" {
  type      = string
  sensitive = true  
}

variable "rollouts_external_ip" {
  type      = string
  sensitive = true  
}

variable "opentelemetry_external_ip" {
  type      = string
  sensitive = true  
}

variable "node_red_external_ip" {
  type      = string
  sensitive = true  
}