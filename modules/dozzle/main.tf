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

resource "local_file" "dozzle_remote_agent_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/template/spec/containers/0/env/1/value"
      value = var.dozzle_remote_agents
    }
  ])
  filename = "${var.overlays_dir}/dozzle-remote-agent.patch.yaml"
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
      },
      {
        target = {
          kind = "Deployment"
          name = "dozzle"
        }
        path = "dozzle-remote-agent.patch.yaml"
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
