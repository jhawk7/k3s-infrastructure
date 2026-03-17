locals {
  namespace = "metallb-system"
  metallb_dir = "${var.init_dir}/base/metallb"
  overlays_dir = "${var.init_dir}/overlays"
}

data "http" "metallb" {
  url = "https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml"
}

resource "local_file" "metallb_manifest" {
  depends_on = [ data.http.metallb ]
  filename = "${local.metallb_dir}/metallb.deploy.yaml"
  content  = data.http.metallb.response_body
}

resource "local_file" "metallb_ip_pool_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/addresses"
      value = [var.metallb_ip_pool]
    }
  ])

  filename = "${local.overlays_dir}/metallb_ip_pool.patch.yaml"
}

resource "local_file" "metallb_deployment_patch" {
  depends_on = [ resource.local_file.metallb_manifest ]
  content = yamlencode([
    {
      op   = "add"
      path = "/spec/template/spec/nodeSelector"
      value = { type = "controller" }
    }
  ])

  filename = "${local.overlays_dir}/metallb_deployment.patch.yaml"
}

resource "local_file" "metallb_kustomization" {
  depends_on = [ local_file.metallb_ip_pool_patch ]
  filename = "${local.overlays_dir}/kustomization.yaml"
  content = yamlencode({
    resources = [
      "../base"
    ]
    patches = [
      {
        target = {
          kind = "IPAddressPool"
          name = "metallb-ip-pool"
        }
        path = "metallb_ip_pool.patch.yaml"
      },
      {
        target = {
          kind = "Deployment"
          name = "controller"
        }
        path = "metallb_deployment.patch.yaml"
      }
    ]
  })
}

resource "null_resource" "render_kustomize" {
  depends_on = [
    local_file.metallb_kustomization,
  ]

  provisioner "local-exec" {
    command = "kubectl apply -k ${local.overlays_dir}"
  }
}
