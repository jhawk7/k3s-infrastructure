# nfs helm release

locals {
  namespace = "nfs-csi-provisioner"
}
resource "helm_release" "csi_driver_nfs" {
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  namespace  = "nfs-csi-provisioner"
  version = "4.13.0"

  values = [
    yamlencode({
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
      controller = {
        nodeSelector = {
          type = "controller"
        }
      }
      tolerations = [
        {
          key      = "type"
          operator = "Equal"
          value    = "controller"
          effect   = "NoSchedule"
        }
      ]
    })
  ]
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
    secretGenerator = [
      {
        name = "${local.namespace}-registry-credentials"
        namespace = local.namespace
        files = [".dockerconfigjson=env_files/.docker-config.json"]
        type = "kubernetes.io/dockerconfigjson"
      }
    ]

    patches = [
      {
        target = {
          kind = "StorageClass"
          name = "nfs"
        }
        path = "nfs-storage.patch.yaml"
      },
      {
        target = {
          kind = "StorageClass"
          name = "nfs-retain"
        }
        path = "nfs-storage.patch.yaml"
      }
    ]
  }
}