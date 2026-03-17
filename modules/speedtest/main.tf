locals {
  namespace = "speedtest"
}

output "kustomization_fragment" {
  value = {
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
