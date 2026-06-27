locals {
  namespace = "dozzle"
}



resource "local_file" "dozzle_svc_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/loadBalancerIP"
      value = var.dozzle_external_ip
    }
  ])
  filename = "${var.overlays_dir}/dozzle-svc.patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "dozzle-svc"
        }
        path = "dozzle-svc.patch.yaml"
      }
    ]
  
    secretGenerator = [ 
      {
        name = "${local.namespace}-registry-credentials",
        namespace = local.namespace,
        files = [".dockerconfigjson=env_files/.docker-config.json"],
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }  
}
