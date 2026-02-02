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
      }
    ]
  }
}