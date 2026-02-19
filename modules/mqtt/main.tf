// generate password file secret based on password.txt
// generate configmap based on mosquitto.conf
// create initialize container in yaml to mount files into config log data dirs

output "kustomization_fragment" {
  value = {
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
      }
    ]
  }
}