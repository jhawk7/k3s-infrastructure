# Helm install for InfluxDB
locals {
  namespace = "influxdb"
}

resource "kubernetes_namespace_v1" "influxdb" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret_v1" "influxdb_auth" {
  depends_on = [ kubernetes_namespace_v1.influxdb ]
  metadata {
    name      = "influxdb-auth"
    namespace = local.namespace
  }
  type = "Opaque"
  data = jsondecode(file("${path.root}/manifests/overlays/env_files/influxdb-auth.json"))
}

resource "kubernetes_secret_v1" "docker_registry" {
  depends_on = [ kubernetes_namespace_v1.influxdb ]
  metadata {
    name      = "${local.namespace}-registry-credentials"
    namespace = local.namespace
  }

  # Use the specific Kubernetes type for registry credentials
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = file("${path.root}/manifests/overlays/env_files/.docker-config.json")
  }
}

resource "helm_release" "influxdb" {
  depends_on = [ kubernetes_secret_v1.influxdb_auth, kubernetes_secret_v1.docker_registry ]
  name       = "influxdb"
  repository = "https://helm.influxdata.com/"
  chart      = "influxdb2"
  namespace  = local.namespace
  version = "2.1.2"

  values = [
    yamlencode({
      image = {
        pullSecrets = ["${local.namespace}-registry-credentials"]
      }
      service = {
        type = "LoadBalancer"
        loadBalancerIP = var.external_ip
      }
      persistence = {
        enabled = true
        storageClass = "nfs-retain"
        size = "2Gi"
      }
      adminUser = {
        organization = "bill-parser"
        bucket = "bills"
        existingSecret = "influxdb-auth"
      }
      initScripts = {
        enabled = true
        scripts = {
          "bill-parser-setup.sh" = <<-EOT
            #!/bin/bash
            # Create orgs
            influx org create --name proxmox

            # Create buckets
            influx bucket create --name proxmox-metrics --org proxmox --retention 720h

          EOT
        }
      }
    })
  ]
}
