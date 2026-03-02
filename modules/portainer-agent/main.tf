locals {
  namespace = "portainer-agent"
}

resource "local_file" "portainer_agent_svc_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/loadBalancerIP"
      value = var.external_ip
    }
  ])
  filename = "${var.overlays_dir}/portainer-agent-svc.patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "portainer-agent-svc"
        }
        path = "portainer-agent-svc.patch.yaml"
      }
    ]
    secretGenerator = [
      {
        name = "${local.namespace}-registry-credentials"
        namespace = local.namespace
        files = [".dockerconfigjson=env_files/.docker-config.json"]
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }  
}
