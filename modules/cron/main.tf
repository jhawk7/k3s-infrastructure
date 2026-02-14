output "kustomization_fragment" {
  value = {
    secretGenerator = [ 
      {
        name = "braves-alert-secret"
        namespace = "cron"
        envs = ["env_files/cron-braves-alert.env"]
        type = "Opaque"
      },
      {
        name = "smtp-cron-secret"
        namespace = "cron"
        envs = ["env_files/cron-smtp.env"]
        type = "Opaque"
      },
      {
        name = "clean-dishwasher-secret"
        namespace = "cron"
        envs = ["env_files/cron-clean-dw.env"]
        type = "Opaque"
      }
    ]
  }  
}
