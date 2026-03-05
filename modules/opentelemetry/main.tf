//todo
// opentel namespace
// secret for registry creds
// patch for load balancer ip
// helm release

locals {
  namespace = "opentel"
}

resource "kubernetes_namespace_v1" "opentel" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "otel_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "opentel"
  create_namespace = true

  values = [
    yamlencode({
      # mode is REQUIRED and must be 'daemonset', 'deployment', or 'statefulset'
      mode = "deployment" 

      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = { endpoint = "0.0.0.0:4317" }
              http = { endpoint = "0.0.0.0:4318" }
            }
          }
        }
        exporters = {
          # Default debug exporter for verifying connectivity
          debug = {
            verbosity = "detailed"
          }
        }
        service = {
          pipelines = {
            traces = {
              receivers = ["otlp"]
              exporters = ["debug"]
            }
            metrics = {
              receivers = ["otlp"]
              exporters = ["debug"]
            }
          }
        }
      }
    })
  ]
}