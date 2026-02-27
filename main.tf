locals {
  overlays_dir = "${path.root}/manifests/overlays"
  base_dir = "${path.root}/manifests/base"
  docker_config_b64 = base64encode(file("${path.root}/manifests/overlays/env_files/.docker-config.json"))
  kustomize_fragments = [
    #module.metallb.kustomization_fragment,
    #module.smb-storage.kustomization_fragment,
    module.nfs-storage.kustomization_fragment,
    module.counter-backend.kustomization_fragment,
    module.cron.kustomization_fragment,
    module.mqtt.kustomization_fragment
  ]
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "null_resource" "create_overlays_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.overlays_dir}"
  }
}

# module "metallb" {
#   depends_on = [ null_resource.create_overlays_dir ]
#   source = "./modules/metallb"
#   metallb_ip_pool = var.metallb_ip_pool
#   overlays_dir = local.overlays_dir
# }

# module "smb-storage" {
#   depends_on = [ null_resource.create_overlays_dir ]
#   source = "./modules/smb-storage"
#   smb_source = var.smb_source
#   overlays_dir = local.overlays_dir
# }

module "nfs-storage" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/nfs-storage"
  nfs_server = var.nfs_server
  overlays_dir = local.overlays_dir
}
module "counter-backend" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/counter-backend"
  external_ip = var.counter_producer_external_ip
  overlays_dir = local.overlays_dir
  docker_config_b64 = local.docker_config_b64
}

module "cron" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/cron"
  overlays_dir = local.overlays_dir
  docker_config_b64 = local.docker_config_b64
}

module "mqtt" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/mqtt"
  external_ip = var.mqtt_external_ip
  overlays_dir = local.overlays_dir
  docker_config_b64 = local.docker_config_b64
}

resource "local_file" "kustomization" {
  depends_on = [ 
    #module.metallb,
    #module.smb-storage,
    module.nfs-storage,
    module.counter-backend, 
    module.cron,
    module.mqtt
  ]

  filename = "${local.overlays_dir}/kustomization.yaml"
  content = yamlencode({
    apiVersion = "kustomize.config.k8s.io/v1beta1"
    kind = "Kustomization"
    resources = concat(["../base"], flatten([
      for f in local.kustomize_fragments : lookup(f, "resources", [])
    ]))
    patches = flatten([
      for f in local.kustomize_fragments : lookup(f, "patches", [])
    ])
    secretGenerator = flatten([
      for f in local.kustomize_fragments : lookup(f, "secretGenerator", [])
    ])
    generatorOptions = {
      disableNameSuffixHash = true
    }
  })
}

resource "null_resource" "render_kustomize" {
  depends_on = [
    local_file.kustomization
  ]

  provisioner "local-exec" {
    command = "kubectl kustomize ${path.root}/manifests/overlays > ${path.root}/outplans/rendered.yaml && echo 'run `kubectl apply -f ${path.root}/outplans/rendered.yaml` to apply the rendered manifests'"
  }

  triggers = {
    always_run = timestamp()
  }
}
