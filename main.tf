locals {
  overlays_dir = "${path.root}/manifests/overlays"
  base_dir = "${path.root}/manifests/base"
  kustomize_fragments = [
    #module.metallb.kustomization_fragment,
    module.nfs-storage.kustomization_fragment,
    module.prometheus.kustomization_fragment,
    module.grafana.kustomization_fragment,
    module.counter-backend.kustomization_fragment,
    module.cron.kustomization_fragment,
    module.mqtt.kustomization_fragment,
    module.portainer-agent.kustomization_fragment,
    module.influxdb.kustomization_fragment,
    module.opentelemetry.kustomization_fragment,
    module.argocd.kustomization_fragment,
    module.node-red.kustomization_fragment
  ]
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
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

module "nfs-storage" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/nfs-storage"
  nfs_server = var.nfs_server
  overlays_dir = local.overlays_dir
}

module "prometheus" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/prometheus"
  external_ip = var.prom_external_ip
  node5_ip = var.node5_ip
  node6_ip = var.node6_ip
  vnas_ip = var.vnas_ip
  vnode_ip = var.vnode_ip
}

module "grafana" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/grafana"
  external_ip = var.grafana_external_ip
  influxdb_admin_user = var.influxdb_admin_user
  influxdb_admin_password = var.influxdb_admin_password
  influxdb_bills_token = var.grafana_influxdb_bills_token
  influxdb_proxmox_token = var.grafana_influxdb_proxmox_token
}

module "counter-backend" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/counter-backend"
  external_ip = var.counter_producer_external_ip
  overlays_dir = local.overlays_dir
}

module "cron" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/cron"
  overlays_dir = local.overlays_dir
}

module "mqtt" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/mqtt"
  external_ip = var.mqtt_external_ip
  overlays_dir = local.overlays_dir
}

module "portainer-agent" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/portainer-agent"
  external_ip = var.portainer_agent_external_ip
  overlays_dir = local.overlays_dir
}

module "influxdb" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/influxdb"
  external_ip = var.influxdb_external_ip
  #overlays_dir = local.overlays_dir
}

module "opentelemetry" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/opentelemetry"
  external_ip = var.opentelemetry_external_ip
}

module "argocd" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/argocd"
  rollouts_external_ip = var.rollouts_external_ip
  argocd_external_ip = var.argocd_external_ip
}

module "node-red" {
  depends_on = [ null_resource.create_overlays_dir ]
  source = "./modules/node-red"
  external_ip = var.node_red_external_ip
  overlays_dir = local.overlays_dir
}

resource "local_file" "kustomization" {
  depends_on = [ 
    #module.metallb,
    module.nfs-storage,
    module.prometheus,
    module.grafana,
    module.counter-backend, 
    module.cron,
    module.mqtt,
    module.portainer-agent,
    module.influxdb,
    module.opentelemetry,
    module.argocd,
    module.node-red
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
