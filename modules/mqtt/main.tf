// generate password file secret based on password.txt
// generate configmap based on mosquitto.conf
// create initialize container in yaml to mount files into config log data dirs

resource "local_file" "mqtt_svc_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/spec/loadBalancerIP"
      value = var.external_ip
    }
  ])
  filename = "${var.overlays_dir}/mqtt-svc.patch.yaml"
}

output "kustomization_fragment" {
  value = {
    patches = [
      {
        target = {
          kind = "Service"
          name = "mqtt-service"
        }
        path = "mqtt-svc.patch.yaml"
      }
    ]

    secretGenerator = [
      {
        name = "mqtt-sub-client-redis-env"
        namespace = "mqtt"
        envs = ["env_files/mqtt-redis.env"]
        type = "Opaque"
      },
      {
        name = "mqtt-sub-client-secret",
        namespace = "mqtt",
        envs = ["env_files/mqtt-sub-client-secret.env"],
        type = "Opaque"
      },
      {
        name = "mqtt-init-secret-files",
        namespace = "mqtt",
        files = ["env_files/mosquitto.conf", "env_files/mqtt-passwd.txt"],
        type = "Opaque"
      },
      {
        name = "mosquitto-exporter-env",
        namespace = "mqtt",
        envs = ["env_files/mqtt-exporter.env"],
        type = "Opaque"
      }
    ]
  }
}