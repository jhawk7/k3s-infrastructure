# Node-RED Module

locals {
  namespace = "node-red"
}

resource "local_file" "node_red_patch" {
  content = yamlencode([
    {
      op    = "replace"
      path  = "/spec/loadBalancerIP"
      value = var.external_ip
    }
  ])
  filename = "${var.overlays_dir}/node-red-svc.patch.yaml"
}

output "kustomization_fragment" {
  depends_on = [ local_file.node_red_patch ]
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "node-red-svc"
        }
        path = "node-red-svc.patch.yaml"
      }
    ]
  }
}
