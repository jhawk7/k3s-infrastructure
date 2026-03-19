# nfs helm release

locals {
  namespace = "nfs-csi-provisioner"
  share = "/srv/nfs-storage"
}

resource "kubernetes_namespace_v1" "nfs_csi_provisioner" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret_v1" "docker_registry" {
  depends_on = [ kubernetes_namespace_v1.nfs_csi_provisioner ]
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
resource "helm_release" "csi_driver_nfs" {
  depends_on = [ kubernetes_secret_v1.docker_registry ]
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  namespace  = "nfs-csi-provisioner"
  version = "4.13.0"
  create_namespace = false

  values = [
    yamlencode({
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
      controller = {
        nodeSelector = {
          type = "controller"
        }
        tolerations = [
          {
            key = "type"
            operator = "Equal"
            value = "controller"
            effect = "NoSchedule"
          }
        ] 
      }
      storageClasses = [
        {
          name = "nfs"
          default = true
          parameters = {
            server = var.nfs_server
            share = local.share
          }
          volumeBindingMode = "Immediate"
          reclaimPolicy = "Delete"
        },
        {
          name = "nfs-retain"
          parameters = {
            server = var.nfs_server
            share = local.share
          }
          volumeBindingMode = "Immediate"
          reclaimPolicy = "Retain"
        }
      ]
    })
  ]
}