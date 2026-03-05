/*TODO
- install with helm provider
- configure LBs for prometheus server
- set PV space
- configure scrape targets
*/

resource "kubernetes_namespace_v1" "prometheus" {
  metadata {
    name = local.namespace 
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart = "oci://ghcr.io/prometheus-community/charts/prometheus"
  namespace  = local.namespace
  version = "28.13.0"
  
  values = [
    yamlencode({
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
      server = {
        persistentVolume = {
          storageClass = "nfs"
          size = "4Gi"
        }
        retention = "15d"
        service = {
          type = "LoadBalancer"
          loadBalancerIP = var.external_ip
        }
      }
      alertmanager = {
        enabled = false
      }
      extraScrapeConfigs = local.extraScrapeConfigs
    })
  ]

}

locals {
  namespace = "prometheus"
  opentel_svc = "opentel-collector-opentelemetry-collector.opentel.svc.cluster.local"
  extraScrapeConfigs = <<-EOT
    - job_name: 'node6'
      static_configs:
        - targets: ['${var.node6_ip}:9100']
    - job_name: 'vnode'
      static_configs:
        - targets: ['${var.vnode_ip}:9100']
    - job_name: 'vnas'
      static_configs:
        - targets: ['${var.vnas_ip}:9100']
    - job_name: 'pihole'
      static_configs:
        - targets: ['${var.node6_ip}:9617']  
    - job_name: 'samba-exporter-nas'
      metrics_path: metrics
      scrape_interval: 10s
      static_configs:
        - targets: ['${var.vnas_ip}:9922']
    - job_name: 'mqtt-exp'
      scrape_interval: 10s
      static_configs:
        - targets: ['mosquitto-exporter-service.mqtt.svc.cluster.local:9234']
    - job_name: 'speedtest-exporter'
      scrape_interval: 30m
      scrape_timeout: 1m
      static_configs:
        - targets: ['speedtester-svc.speedtest.svc.cluster.local:9798']
    - job_name: 'otel-collector'
      scrape_interval: 10s
      static_configs:
        - targets: ['${local.opentel_svc}:8889', '${local.opentel_svc}:8888']
  EOT
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