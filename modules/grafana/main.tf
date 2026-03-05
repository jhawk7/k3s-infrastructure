/*
- setup grafana with helm provider
- configure LB for grafana dashboard
- configure datasource for prometheus, influxdb
- configure dashboards from json files
- configure datasources
*/
locals {
	namespace = "grafana"
}

resource "helm_release" "grafana" {
	name       = "grafana"
	chart = "oci://ghcr.io/grafana-community/helm-charts/grafana"
	namespace  = local.namespace
	version    = "12.4.0"

	values = [
		yamlencode({
      globals = {
        imagePullSecrets = [
          { name = "${local.namespace}-registry-credentials" }
        ]
      }
			service = {
				type = "LoadBalancer"
				loadBalancerIP = var.external_ip
			}
      nodeSelector = {
        type = "agent"
      }
      persistence = {
        enabled = true
        storageClassName = "nfs-retain"
        size = "4Gi"
      }
			admin = {
        existingSecret = "grafana-admin-credentials"
      }
      datasources = {
        "datasources.yaml" = {
          apiVersion  = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              access    = "proxy"
              url       = "http://prometheus-server.prometheus.svc.cluster.local"
              basicAuth = false
            },
            {
              name      = "InfluxDB-Bills"
              type      = "influxdb"
              access    = "proxy"
              url       = "http://influxdb-svc.influxdb.svc.cluster.local:8086"
              basicAuth = true
              uid = "influxdb-bills"
              basicAuthUser = var.influxdb_admin_user
              secureJsonData = {
                basicAuthPassword = var.influxdb_admin_password
              }
              jsonData = {
                version = "Flux"
                organization = "bill-parser"
                defaultBucket = "bills"
                token = var.influxdb_bills_token
              }
            },
            {
              name      = "InfluxDB-Bills"
              type      = "influxdb"
              access    = "proxy"
              url       = "http://influxdb-svc.influxdb.svc.cluster.local:8086"
              basicAuth = true
              uid = "influxdb-proxmox"
              basicAuthUser = var.influxdb_admin_user
              secureJsonData = {
                basicAuthPassword = var.influxdb_admin_password
              }
              jsonData = {
                version = "Flux"
                organization = "proxmox"
                defaultBucket = "proxmox-metrics"
                token = var.influxdb_proxmox_token
              }
            }
          ]
        }
      }
      dashboards = {
        Bill_Tracker = {
          json = file("${path.module}/grafana-dashboards/Bill-Tracker.json")
        }
        Kubernetes_Cluster_Prometheus = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Cluster-Prometheus.json")
        }
        Kubernetes_Deployment_Metrics = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Deployment-metrics.json")
        }
        Kubernetes_Kafka = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Kafka.json")
        }
        "Bill-Tracker" = {
          json = file("${path.module}/grafana-dashboards/Bill-Tracker.json")
        }
        "Kubernetes-Cluster-Prometheus" = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Cluster-Prometheus.json")
        }
        "Kubernetes-Deployment-Metrics" = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Deployment-Metrics.json")
        }
        "Kubernetes-Kafka" = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Kafka.json")
        }
        "Kubernetes-Persistent-Volumes" = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Persistent-Volumes.json")
        }
        "Kubernetes-Pod-Metrics" = {
          json = file("${path.module}/grafana-dashboards/Kubernetes-Pod-Metrics.json")
        }
        "Mosquitto-Exporter" = {
          json = file("${path.module}/grafana-dashboards/Mosquitto-Exporter.json")
        }
        "NAS-Samba-Service-V1.21" = {
          json = file("${path.module}/grafana-dashboards/NAS-Samba-Service-V1.21.json")
        }
        "Node-Exporter-Full" = {
          json = file("${path.module}/grafana-dashboards/Node-Exporter-Full.json")
        }
        "Pi-Thermo-Crawl-Space" = {
          json = file("${path.module}/grafana-dashboards/Pi-Thermo-Crawl-Space.json")
        }
        "Picow-House-Plant-Moisture" = {
          json = file("${path.module}/grafana-dashboards/Picow-House-Plant-Moisture.json")
        }
        "Picow-Temp-and-RH-House" = {
          json = file("${path.module}/grafana-dashboards/Picow-Temp-and-RH-House.json")
        }
        "Pihole-Exporter" = {
          json = file("${path.module}/grafana-dashboards/Pihole-Exporter.json")
        }
        "Proxmox-Cluster-Flux" = {
          json = file("${path.module}/grafana-dashboards/Proxmox-Cluster-Flux.json")
        }
        "Speedtest-Exporter-Dashboard" = {
          json = file("${path.module}/grafana-dashboards/Speedtest-Exporter-Dashboard.json")
        }
      }
    })
  ]
}

output "kustomization_fragment" {
  value = {
    secretGenerator = [
      {
        name = "${local.namespace}-registry-credentials"
        namespace = local.namespace
        files = [".dockerconfigjson=env_files/.docker-config.json"]
        type = "kubernetes.io/dockerconfigjson"
      },
      {
        name = "grafana-admin-credentials"
        namespace = local.namespace
        envs = ["env_files/grafana-creds.env"]
        type = "Opaque"
      }
    ]
  }
}