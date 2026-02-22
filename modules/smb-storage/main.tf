resource "local_file" "smb_storage_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/parameters/source"
      value = var.smb_source
    }
  ])

  filename = "${var.overlays_dir}/smb-storage.patch.yaml"
}

output "kustomization_fragment" {
  depends_on = [ local_file.smb_storage_patch ]
  value = {
    patches = [
      {
        target = {
          kind = "StorageClass"
          name = "smb"
        }
        path = "smb-storage.patch.yaml"
      }
    ]

    secretGenerator = [
      {
        name = "smb-secret"
        namespace = "smb-csi-provisioner"
        envs = ["env_files/smb-secret.env"]
        type = "Opaque"
      }
    ]
  }
}