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

resource "kubernetes_secret_v1" "docker_registry" {
  depends_on = [ kubernetes_namespace_v1.argocd ]
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

# 1. Install Argo CD
resource "helm_release" "argocd" {
  depends_on = [ kubernetes_secret_v1.docker_registry]
  name             = "argocd"
  repository       = local.argo_repo
  chart            = "argo-cd"
  namespace        = local.namespace

  # Optional: Configure basic settings like disabling the admin password 
  # or setting up an Ingress via values.

  values = [
    yamlencode({
      namespaceOverride = local.namespace
      global = {
        imagePullSecrets = [
          { name = "${local.namespace}-registry-credentials" }
        ]
      }
      server = {
        service = {
          type = "LoadBalancer"
          loadBalancerIP = var.argocd_external_ip
        }
      }
    })
  ]
}

# 2. Install Argo Rollouts (Progressive Delivery Controller)
resource "helm_release" "argo_rollouts" {
  depends_on = [helm_release.argocd, kubernetes_secret_v1.docker_registry] # Ensure Argo CD is installed first
  name             = "argo-rollouts"
  repository       = local.argo_repo
  chart            = "argo-rollouts"
  namespace        = local.namespace

  values = [
    yamlencode({
      namespaceOverride = local.namespace
      dashboard = {
        enabled = true
        service = {
          type = "LoadBalancer"
          loadBalancerIP = var.rollouts_external_ip
        }
      }
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
    })
  ]
}

# 3. Install Argo CD Image Updater
resource "helm_release" "argocd_image_updater" {
  depends_on = [helm_release.argocd, kubernetes_secret_v1.docker_registry] # Ensure Argo CD is installed first
  name       = "argocd-image-updater"
  repository = local.argo_repo
  chart      = "argocd-image-updater"
  namespace  = local.namespace # Typically installed in the same namespace as Argo CD

  # Requires specific configuration to talk to the Argo CD API if 
  # using write-back methods.
  values = [
    yamlencode({
      image = {
        pullPolicy = "IfNotPresent"
      }
      imagePullSecrets = [
        { name = "${local.namespace}-registry-credentials" }
      ]
      crds = {
        install = true
        keep = false
      }
      config = {
        registries = [
          {
            name = "dockerhub"
            api_url = "https://registry-1.docker.io"
            default = true
            insecure = false
            credentials = "pullsecret:${local.namespace}-registry-credentials"
          }
        ]
      }
    })
  ]
}