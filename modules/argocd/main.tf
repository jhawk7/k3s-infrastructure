/*
- install argocd with helm
- install argocd-image-updater with helm
- install argo-rollouts with helm
- configure LBs for argocd and rollouts dashboard
- use node5 taint dedicated=blocked:NoSchedule
*/

# Shared repository URL for all Argo projects
locals {
  namespace = "argocd"
  argo_repo = "https://argoproj.github.io/argo-helm"
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = local.namespace
  }
}

# 1. Install Argo CD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = local.argo_repo
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.7.1" # Example version; check Artifact Hub for latest

  # Optional: Configure basic settings like disabling the admin password 
  # or setting up an Ingress via values.
}

# 2. Install Argo Rollouts (Progressive Delivery Controller)
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = local.argo_repo
  chart            = "argo-rollouts"
  namespace        = "argo-rollouts"
  create_namespace = true
  version          = "2.40.6"

  values = [
    yamlencode({
      dashboard = {
        enabled = true
        service = {
          type = "LoadBalancer"
          loadBalancerIP = var.rollouts_external_ip
        }
      }
      nodeSelector = {
        type = "agent"
      }
    })
  ]
  set {
    name  = "dashboard.enabled"
    value = "true" # Enables the Rollouts web dashboard
  }
}

# 3. Install Argo CD Image Updater
resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  repository = local.argo_repo
  chart      = "argocd-image-updater"
  namespace  = "argocd" # Typically installed in the same namespace as Argo CD
  version    = "0.11.1"

  # Requires specific configuration to talk to the Argo CD API if 
  # using write-back methods.
  values = [
    yamlencode({
      config = {
        argocd = {
          server_addr = "argocd-server.argocd.svc.cluster.local"
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}

output "kustomization_fragment" {
  value = {
    secretGenerator = [
      {
        name = "${local.namespace}-registry-credentials"
        namespace = kubernetes_namespace_v1.argocd.metadata[0].name
        files = [".dockerconfigjson=env_files/.docker-config.json"]
        type = "kubernetes.io/dockerconfigjson"
      }
    ]
  }
}