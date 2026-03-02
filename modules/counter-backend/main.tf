locals {
  namespace = "go-counter"
}

resource "local_file" "counter_svc_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/loadBalancerIP"
      value = var.external_ip
    }
  ])

  filename = "${var.overlays_dir}/counter-producer-svc.patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "go-counter-backend-svc"
        }
        path = "counter-producer-svc.patch.yaml"
      }
    ]

    secretGenerator = [
      {
        name = "go-counter-backend-redis-env"
        namespace = "go-counter"
        envs = ["env_files/go-counter-redis.env"]
        type = "Opaque"
      },
      {
        name = "go-counter-backend-mqtt-env"
        namespace = "go-counter"
        envs = ["env_files/go-counter-mqtt.env"]
        type = "Opaque"
      },
      {
        name = "go-counter-consumer-env"
        namespace = "go-counter"
        envs = ["env_files/go-counter-consumer.env"]
        type = "Opaque"
      },
      {
        name = "go-counter-producer-env"
        namespace = "go-counter"
        envs = ["env_files/go-counter-producer.env"]
        type = "Opaque"
      },
      {
        name = "${local.namespace}-registry-credentials",
        namespace = local.namespace,
        files = [".dockerconfigjson=env_files/.docker-config.json"],
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }
}