locals {
  namespace = "opentel"
}

resource "kubernetes_namespace_v1" "opentel" {
  metadata {
    name = local.namespace
  }
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

resource "helm_release" "otel_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = local.namespace
  version = "0.146.1"

  values = [
    yamlencode({
      # mode is REQUIRED and must be 'daemonset', 'deployment', or 'statefulset'
      mode = "deployment"
      image = {
        repository = "otel/opentelemetry-collector"
        tag = "latest"
      } 
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
      nodeSelector = {
        type = "agent"
      }
      ports = {
        metrics = {
          enabled = true
          containerPort = 8888
          servicePort = 8888
          protocol = "TCP"
        }
        prom-exporter = {
          enabled = true
          containerPort = 8889
          servicePort = 8889
          protocol = "TCP"
        }
      }
      service = {
        type = "LoadBalancer"
        loadBalancerIP = var.external_ip
      }
      config = {
        exporters = {
          prometheus = {
            endpoint = "0.0.0.0:8889"
          }
        }
        service = {
          pipelines = {
            metrics = {
              exporters = ["prometheus"]
            }
          }
        }
      }
    })
  ]
}

# output "kustomization_fragment" {
#   value = {
#     secretGenerator = [
#       {
#         name = "${local.namespace}-registry-credentials"
#         namespace = local.namespace
#         files = [".dockerconfigjson=env_files/.docker-config.json"]
#         type = "kubernetes.io/dockerconfigjson"
#       }
#     ]
#   }
# }
