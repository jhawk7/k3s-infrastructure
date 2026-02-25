# K3s Infrastructure Setup

This repository contains the infrastructure configuration for a K3s-based Kubernetes cluster, managed with Terraform and Kubernetes manifests. It is designed to automate the deployment and management of various services, including application backends, cron jobs, storage, networking, and monitoring tools.

## Structure

- **main.tf / terraform.tfvars / variables.tf**: Core Terraform files for cluster provisioning and configuration.
- **modules/**: Modular Terraform configurations for each component (e.g., ArgoCD, counter-backend, cron, grafana, metallb, mqtt, prometheus, resources, smb-storage).
- **manifests/**: Kubernetes manifests and kustomizations for deploying workloads and infrastructure components.
  - **argocd/**: ArgoCD application manifests for GitOps deployment.
  - **base/**: Base kustomization and app manifests for services (dotnetAPI, mqtt-sub, counter-backend, cron, metallb, mqtt-service, smb-storage, speedtest).
  - **overlays/**: Patch files and environment configurations for customizing deployments.
- **outplans/**: Terraform plan outputs and rendered Kubernetes manifests.

## Key Components

- **ArgoCD**: GitOps tool for managing Kubernetes resources.
- **Counter Backend**: Application backend service.
- **Cron Jobs**: Scheduled tasks for alerts and data cleaning.
- **Grafana & Prometheus**: Monitoring and visualization stack.
- **Metallb**: Load balancer for bare-metal Kubernetes.
- **MQTT**: Messaging service for IoT and microservices.
- **SMB Storage**: Network file storage integration.

## How It Runs

1. **Terraform Initialization**:
   - Configure variables in `terraform.tfvars`.
   - Run `terraform init` to initialize the working directory.
   - Apply infrastructure with `terraform apply`.

2. **Kubernetes Manifests**:
   - Manifests are organized under `manifests/`.
   - Use `kubectl apply -k manifests/base` to deploy base workloads.
   - Use overlays for environment-specific customizations.

3. **ArgoCD GitOps**:
   - ArgoCD applications are defined in `manifests/argocd/`.
   - ArgoCD syncs and manages application deployments from this repository.

4. **Monitoring & Storage**:
   - Grafana and Prometheus are deployed for cluster monitoring.
   - SMB storage is integrated for persistent volumes.

## Customization

- Edit `terraform.tfvars` and module variables for infrastructure changes.
- Update Kubernetes manifests and overlays for application and environment tweaks.
- Add new modules or manifests as needed for additional services.

## Usage

```bash
# Terraform
terraform init
terraform plan
terraform apply

# Kubernetes (with kubectl)
kubectl apply -k manifests/base
# For overlays:
kubectl apply -k manifests/overlays
```

## Requirements

- [Terraform](https://www.terraform.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [K3s](https://k3s.io/)

## Notes

- Ensure K3s is installed and accessible.
- Review environment files in `manifests/overlays/env_files/` for secrets and configuration.
- Use ArgoCD for automated GitOps deployments.

---

For detailed module and manifest documentation, see the respective folders.
