locals {
  namespace = "apps"
}

resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = local.namespace
  }
}

resource "local_file" "av_parser_argo_patch" {
  content = yamlencode([
    {
      op = "replace"
      path = "/spec/source/kustomize/patches/0/patch"
      value = <<-EOT
      - op: "replace"
        path: "/spec/loadBalancerIP"
        value: "${var.av_parser_external_ip}"
      EOT
    }
  ])

  filename = "${var.overlays_dir}/av-parser-argo-patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Application"
          name = "av-parser-web"
        }
        path = "av-parser-argo-patch.yaml"
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
        name = "${local.namespace}-registry-credentials",
        namespace = local.namespace,
        files = [".dockerconfigjson=env_files/.docker-config.json"],
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }
}