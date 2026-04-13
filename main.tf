locals {
  overlays_dir = "${path.root}/manifests/overlays"
  base_dir = "${path.root}/manifests/base"
  init_dir = "${path.root}/manifests/initial"

  kustomize_fragments = [
    module.go-counter-backend.kustomization_fragment,
    module.cron.kustomization_fragment,
    module.mqtt.kustomization_fragment,
    module.portainer-agent.kustomization_fragment,
    module.node-red.kustomization_fragment,
    module.speedtest.kustomization_fragment,
    module.apps.kustomization_fragment
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

provider "time" {
  # No configuration needed for the time provider
}

# terraform {
#   required_providers {
#     time = {
#       source  = "hashicorp/time"
#       version = "~> 0.9"
#     }
#   }
# }


# Phase 1
module "metallb" {
  source = "./modules/metallb"
  metallb_ip_pool = var.metallb_ip_pool
  init_dir = local.init_dir
}

resource "time_sleep" "wait_30_seconds_before_phase_2" {
  create_duration = "30s"
}

# Phase 2
module "nfs-storage" {
  depends_on = [ time_sleep.wait_30_seconds_before_phase_2, module.metallb ]
  source = "./modules/nfs-storage"
  nfs_server = var.nfs_server
  overlays_dir = local.overlays_dir
}

resource "time_sleep" "wait_30_seconds_before_phase_3" {
  depends_on = [ time_sleep.wait_30_seconds_before_phase_2 ]
  create_duration = "30s"
}

#Phase 3
module "prometheus" {
  depends_on = [ time_sleep.wait_30_seconds_before_phase_3, module.nfs-storage ]
  source = "./modules/prometheus"
  external_ip = var.prom_external_ip
  node5_ip = var.node5_ip
  node6_ip = var.node6_ip
  vnas_ip = var.vnas_ip
  vnode_ip = var.vnode_ip
  av_parser_ip = var.av_parser_external_ip
}

module "grafana" {
  depends_on = [ time_sleep.wait_30_seconds_before_phase_3, module.nfs-storage ]
  source = "./modules/grafana"
  external_ip = var.grafana_external_ip
  influxdb_admin_user = var.influxdb_admin_user
  influxdb_admin_password = var.influxdb_admin_password
  influxdb_bills_token = var.grafana_influxdb_bills_token
  influxdb_proxmox_token = var.grafana_influxdb_proxmox_token
}

resource "time_sleep" "wait_20_seconds_before_phase_4" {
  depends_on = [ time_sleep.wait_30_seconds_before_phase_3 ]
  create_duration = "30s"
}

# Phase 4
module "influxdb" {
  depends_on = [ time_sleep.wait_20_seconds_before_phase_4, module.nfs-storage ]
  source = "./modules/influxdb"
  external_ip = var.influxdb_external_ip
}

module "opentelemetry" {
  depends_on = [ time_sleep.wait_20_seconds_before_phase_4, module.nfs-storage ]
  source = "./modules/opentelemetry"
  external_ip = var.opentelemetry_external_ip
}

module "argocd" {
  depends_on = [ time_sleep.wait_20_seconds_before_phase_4, module.nfs-storage ]
  source = "./modules/argocd"
  rollouts_external_ip = var.rollouts_external_ip
  argocd_external_ip = var.argocd_external_ip
}

resource "time_sleep" "wait_20_seconds_before_phase_5" {
  depends_on = [ time_sleep.wait_20_seconds_before_phase_4 ]
  create_duration = "30s"
}

# Phase 5
resource "null_resource" "create_overlays_dir" {
  depends_on = [ time_sleep.wait_20_seconds_before_phase_5 ]
  provisioner "local-exec" {
    command = "mkdir -p ${local.overlays_dir}"
  }
}

module "go-counter-backend" {
  depends_on = [ null_resource.create_overlays_dir, module.nfs-storage, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/go-counter-backend"
  external_ip = var.counter_producer_external_ip
  overlays_dir = local.overlays_dir
}

module "cron" {
  depends_on = [ null_resource.create_overlays_dir, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/cron"
  overlays_dir = local.overlays_dir
}

module "mqtt" {
  depends_on = [ null_resource.create_overlays_dir, module.nfs-storage, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/mqtt"
  external_ip = var.mqtt_external_ip
  overlays_dir = local.overlays_dir
}

module "portainer-agent" {
  depends_on = [ null_resource.create_overlays_dir, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/portainer-agent"
  external_ip = var.portainer_agent_external_ip
  overlays_dir = local.overlays_dir
}

module "node-red" {
  depends_on = [ null_resource.create_overlays_dir, module.nfs-storage, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/node-red"
  external_ip = var.node_red_external_ip
  overlays_dir = local.overlays_dir
}

module "speedtest" {
  depends_on = [ null_resource.create_overlays_dir, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/speedtest"
}

module "apps" {
  depends_on = [ null_resource.create_overlays_dir, time_sleep.wait_20_seconds_before_phase_5 ]
  source = "./modules/apps"
  overlays_dir = local.overlays_dir
  av_parser_external_ip = var.av_parser_external_ip
  go_bills_parser_external_ip = var.go_bills_parser_external_ip
}

resource "local_file" "kustomization" {
  depends_on = [
    time_sleep.wait_20_seconds_before_phase_5, 
    module.go-counter-backend, 
    module.cron,
    module.mqtt,
    module.portainer-agent,
    module.node-red,
    module.speedtest,
    module.apps
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
