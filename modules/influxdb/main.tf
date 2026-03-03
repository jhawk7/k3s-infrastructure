# InfluxDB Helm Release Module

locals {
  namespace = "influxdb"
}

resource "local_file" "influxdb_patch" {
  content = yamlencode([
    {
      op    = "replace"
      path  = "/spec/loadBalancerIP"
      value = var.external_ip
    }
  ])
  filename = "${var.overlays_dir}/influxdb-svc.patch.yaml"
}

output "kustomization_fragment" {
  depends_on = [ local_file.influxdb_patch ]
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "influxdb-svc"
        }
        path = "influxdb-svc.patch.yaml"
      }
    ]
    
    secretGenerator = [
      {
        name = "influxdb-auth"
        namespace = local.namespace
        envs = ["env_files/influxdb-auth.env"]
        type = "Opaque"
      }
    ]
  }
}
