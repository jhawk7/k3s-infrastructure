locals {
  base_dir = "${path.root}/manifests/base"
}

data "http" "metallb" {
  url = "https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml"
}

resource "local_file" "metallb_manifest" {
  depends_on = [ data.http.metallb ]
  filename = "${local.base_dir}/metallb/metallb.deploy.yaml"
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

  filename = "${var.overlays_dir}/metallb_ip_pool.patch.yaml"
}

resource "local_file" "metallb_deployment_patch" {
  content = yamlencode([
    {
      op   = "add"
      path = "/spec/template/spec/nodeSelector"
      value = { type = "controller" }
    },
    {
      op   = "add"
      path = "/spec/template/spec/tolerations"
       value = {
        key = "dedicated"
        operator = "Equal"
        value = "blocked"
        effect = "NoSchedule"
      }
    }
  ])

  filename = "${var.overlays_dir}/metallb_deployment.patch.yaml"
}

output "kustomization_fragment" {
  depends_on = [ local_file.metallb_ip_pool_patch ]
  value = {
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
          namespace = "metallb-system"
        }
        path = "metallb_deployment.patch.yaml"
      }
    ]
  }
}