locals {
  namespace = "cron"
}

# resource local_file "cron_dockerconfig_patch" {
#   content = yamlencode([
#     {
#       op   = "replace"
#       path = "/data/.dockerconfigjson"
#       value = var.docker_config_b64
#     },
#     {
#       op   = "replace"
#       path = "/metadata/name"
#       value = "${local.namespace}-registry-credentials"
#     },
#     {
#       op   = "replace"
#       path = "/metadata/namespace"
#       value = "${local.namespace}"
#     }
#   ])
#   filename = "${var.overlays_dir}/cron-dockerconfig.patch.yaml"
# }

output "kustomization_fragment" {
  value = {
    secretGenerator = [ 
      {
        name = "braves-alert-secret"
        namespace = "cron"
        envs = ["env_files/cron-braves-alert.env"]
        type = "Opaque"
      },
      {
        name = "smtp-cron-secret"
        namespace = "cron"
        envs = ["env_files/cron-smtp.env"]
        type = "Opaque"
      },
      {
        name = "clean-dishwasher-secret"
        namespace = "cron"
        envs = ["env_files/cron-clean-dw.env"]
        type = "Opaque"
      },
      {
        name = "${local.namespace}-registry-credentials",
        namespace = local.namespace,
        files = [".dockerconfigjson=env_files/.docker-config.json"],
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }  
}
