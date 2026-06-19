variable "prom_external_ip" {
  type      = string
  sensitive = true
}

variable "pushgateway_external_ip" {
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
