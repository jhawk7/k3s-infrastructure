# nfs helm release
resource "helm_release" "csi_driver_nfs" {
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  namespace  = "nfs-csi-provisioner"
  version = "4.13.0"
}

resource "local_file" "nfs_storage_patch" {
  content = yamlencode([
    {
      op   = "replace"
      path = "/parameters/server"
      value = var.nfs_server
    }
  ])

  filename = "${var.overlays_dir}/nfs-storage.patch.yaml"
}

output "kustomization_fragment" {
  depends_on = [ local_file.nfs_storage_patch ]
  value = {
    patches = [
      {
        target = {
          kind = "StorageClass"
          name = "nfs"
        }
        path = "nfs-storage.patch.yaml"
      }
    ]
  }
}