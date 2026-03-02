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