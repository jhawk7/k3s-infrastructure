# Helm install for InfluxDB
locals {
  namespace = "influxdb"
}

resource "helm_release" "influxdb" {
  name       = "influxdb"
  repository = "https://helm.influxdata.com/"
  chart      = "influxdb2"
  namespace  = local.namespace
  create_namespace = true
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

output "kustomization_fragment" {
  value = {
    secretGenerator = [
      {
        name = "influxdb-auth"
        namespace = local.namespace
        envs = ["env_files/influxdb-auth.env"]
        type = "Opaque"
      },
      {
        name = "${local.namespace}-registry-credentials"
        namespace = local.namespace
        files = [".dockerconfigjson=env_files/.docker-config.json"]
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }
}
