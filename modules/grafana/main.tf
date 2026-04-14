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

resource "kubernetes_namespace_v1" "grafana" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret_v1" "grafana_creds" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = local.namespace
  }
  type = "Opaque"
  data = jsondecode(file("${path.root}/manifests/overlays/env_files/grafana-creds.json"))
}

resource "kubernetes_secret_v1" "docker_registry" {
  metadata {
    name      = "${local.namespace}-registry-credentials"
    namespace = local.namespace
  }

  # Use the specific Kubernetes type for registry credentials
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = file("${path.root}/manifests/overlays/env_files/.docker-config.json")
  }
}

resource "helm_release" "grafana" {
  depends_on = [ kubernetes_secret_v1.docker_registry, kubernetes_secret_v1.grafana_creds ]
	name       = "grafana"
	chart = "oci://ghcr.io/grafana-community/helm-charts/grafana"
	namespace  = local.namespace
  version = "11.3.0"

	values = [
		yamlencode({
      global = {
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
              url       = "http://influxdb-influxdb2.influxdb.svc.cluster.local"
              basicAuth = true
              uid = "influxdb-bills"
              basicAuthUser = var.influxdb_admin_user
              secureJsonData = {
                basicAuthPassword = var.influxdb_admin_password
                token = var.grafana_influxdb_token
              }
              jsonData = {
                version = "Flux"
                organization = "bill-parser"
                defaultBucket = "bills"
              }
            },
            {
              name      = "InfluxDB-Proxmox"
              type      = "influxdb"
              access    = "proxy"
              url       = "http://influxdb-influxdb2.influxdb.svc.cluster.local"
              basicAuth = true
              uid = "influxdb-proxmox"
              basicAuthUser = var.influxdb_admin_user
              secureJsonData = {
                basicAuthPassword = var.influxdb_admin_password
                token = var.grafana_influxdb_token
              }
              jsonData = {
                version = "Flux"
                organization = "proxmox"
                defaultBucket = "proxmox-metrics"
              }
            }
          ]
        }
      }
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [{
            name            = "default" # Name of the provider
            orgId           = 1
            folder          = ""        # UI folder to put dashboards in
            type            = "file"
            disableDeletion = false
            editable        = true
            options = {
              # This path MUST match where the Helm chart mounts the JSON
              path = "/var/lib/grafana/dashboards/default"
            }
          }]
        }
      }
      dashboards = {
        default = {
         "Bill-Tracker" = {
          json = file("${path.root}/grafana-dashboards/Bill-Tracker.json")
          }
          "Kubernetes-Cluster-Prometheus" = {
            json = file("${path.root}/grafana-dashboards/Kubernetes-Cluster-Prometheus.json")
          }
          "Kubernetes-Deployment-Metrics" = {
            json = file("${path.root}/grafana-dashboards/Kubernetes-Deployment-Metrics.json")
          }
          "Kubernetes-Kafka" = {
            json = file("${path.root}/grafana-dashboards/Kubernetes-Kafka.json")
          }
          "Kubernetes-Persistent-Volumes" = {
            json = file("${path.root}/grafana-dashboards/Kubernetes-Persistent-Volumes.json")
          }
          "Kubernetes-Pod-Metrics" = {
            json = file("${path.root}/grafana-dashboards/Kubernetes-Pod-Metrics.json")
          }
          "Mosquitto-Exporter" = {
            json = file("${path.root}/grafana-dashboards/Mosquitto-Exporter.json")
          }
          "NAS-Samba-Service-V1.21" = {
            json = file("${path.root}/grafana-dashboards/NAS-Samba-Service-V1.21.json")
          }
          "Node-Exporter-Full" = {
            json = file("${path.root}/grafana-dashboards/Node-Exporter-Full.json")
          }
          "Pi-Thermo-Crawl-Space" = {
            json = file("${path.root}/grafana-dashboards/Pi-Thermo-Crawl-Space.json")
          }
          "Picow-House-Plant-Moisture" = {
            json = file("${path.root}/grafana-dashboards/Picow-House-Plant-Moisture.json")
          }
          "Picow-Temp-and-RH-House" = {
            json = file("${path.root}/grafana-dashboards/Picow-Temp-and-RH-House.json")
          }
          "Pihole-Exporter" = {
            json = file("${path.root}/grafana-dashboards/Pihole-Exporter.json")
          }
          "Proxmox-Cluster-Flux" = {
            json = file("${path.root}/grafana-dashboards/Proxmox-Cluster-Flux.json")
          }
          "Speedtest-Exporter-Dashboard" = {
            json = file("${path.root}/grafana-dashboards/Speedtest-Exporter-Dashboard.json")
          } 
        }
      }
    })
  ]
}

