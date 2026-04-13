locals {
  namespace = "apps"
}

resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = local.namespace
  }
}

# resource "local_file" "av_parser_argo_patch" {
#   content = yamlencode([
#     {
#       op = "replace"
#       path = "/spec/source/kustomize/patches/0/patch"
#       value = <<-EOT
#       - op: "replace"
#         path: "/spec/loadBalancerIP"
#         value: "${var.av_parser_external_ip}"
#       EOT
#     }
#   ])

#   filename = "${var.overlays_dir}/av-parser-argo-patch.yaml"
# }

resource "local_file" "go_bills_api_argo_patch" {
  content = yamlencode([
    {
      op = "replace"
      path = "/spec/source/kustomize/patches/0/patch"
      value = <<-EOT
      - op: "replace"
        path: "/spec/loadBalancerIP"
        value: "${var.go_bills_parser_external_ip}"
      EOT
    }
  ])

  filename = "${var.overlays_dir}/go-bills-api-argo-patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Application"
          name = "go-bills-api"
        }
        path = "go-bills-api-argo-patch.yaml"
      }
    ]

    secretGenerator = [
      {
        name = "av-parser-web-secret"
        namespace = local.namespace
        envs = ["env_files/av-parser-web.env"]
        type = "Opaque"
      },
      {
        name = "go-bills-api-secret",
        namespace = local.namespace,
        envs = ["env_files/go-bills-api.env"],
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