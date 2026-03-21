# k3s Infrastructure Automation ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white) ![Helm](https://img.shields.io/badge/helm-%230F1689.svg?style=flat&logo=helm&logoColor=white) ![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?flat&logo=kubernetes&logoColor=white)

This repository manages a k3s Kubernetes cluster using a modular, phased approach with Terraform, Helm, and Kustomize. The workflow is designed for clarity, repeatability, and extensibility.

---

## Repository Structure

```
main.tf                  # Root Terraform configuration
terraform.tfvars         # Variable values
variables.tf             # Variable declarations
modules/                 # Terraform modules for each component
  argocd/                # ArgoCD deployment
  cron/                  # CronJobs
  go-counter-backend/    # Go backend service
  grafana/               # Grafana monitoring
  influxdb/              # InfluxDB database
  metallb/               # MetalLB load balancer
  mqtt/                  # MQTT broker
  nfs-storage/           # NFS storage
  node-red/              # Node-RED automation
  opentelemetry/         # OpenTelemetry
  portainer-agent/       # Portainer agent
  prometheus/            # Prometheus monitoring
  smb-storage/           # SMB storage
  speedtest/             # Speedtest exporter
manifests/               # Kubernetes manifests and kustomization overlays
  argo-apps/             # ArgoCD application manifests
  base/                  # Base kustomization and resources
  initial/               # Initial cluster setup overlays
  overlays/              # Environment-specific overlays and patches
  env_files/             # Environment variable files
outplans/                # Rendered output plans
  rendered.yaml          # Rendered manifests
terraform.tfstate        # Terraform state file
terraform.tfstate.backup # Terraform state backup
grafana-dashboards/      # Prebuilt Grafana dashboards
```

---

## Execution Flow & Phases


### Phase 1: Networking
- **Modules:**
  - metallb
- **Description:**
  - Sets up MetalLB for bare-metal load balancing.

### Phase 2: Storage
- **Modules:**
  - nfs-storage
- **Description:**
  - Provisions NFS storage for persistent volumes.

### Phase 3: Monitoring
- **Modules:**
  - prometheus
  - grafana
- **Description:**
  - Installs Prometheus and Grafana for monitoring and visualization.

### Phase 4: Databases & Platform Services
- **Modules:**
  - influxdb
  - opentelemetry
  - argocd
- **Description:**
  - Deploys InfluxDB, OpenTelemetry, and ArgoCD for GitOps and observability.

### Phase 5: Application Workloads
- **Modules:**
  - go-counter-backend
  - cron
  - mqtt
  - portainer-agent
  - node-red
  - speedtest
- **Description:**
  - Deploys application workloads and supporting services. Each module may generate kustomization fragments for further customization.

### Phase 6: Kustomize & Final Deployment
- **Kustomize Fragments:**
  - `manifests/base/` and `manifests/overlays/` contain base resources and environment-specific patches.
  - All kustomization fragments from modules are composed and rendered.
  - Apply the rendered manifests to the cluster for final deployment.

---

## How to Use

1. **Initialize Terraform**
   ```sh
   terraform init
   ```
2. **Apply Terraform Plan**
   ```sh
   terraform apply
   ```
   - This triggers all phases in order, provisioning infrastructure and installing Helm charts via modules.
3. **Kustomize Manifests**
   - Kustomize overlays and patches in `manifests/` are composed to generate the final YAMLs.
   - ArgoCD syncs and applies these manifests to the cluster.

---

## Required Secrets & Environment Files

- **manifests/env_files/**: Place required environment variable files here for workloads and services.
- **Expected secrets (examples):**
  - `argocd-admin-secret.yaml` (ArgoCD admin password)
  - `grafana-admin-secret.yaml` (Grafana admin credentials)
  - `influxdb-auth.yaml` (InfluxDB credentials)
  - `mqtt-credentials.yaml` (MQTT broker credentials)
  - `nfs-credentials.yaml` / `smb-credentials.yaml` (Storage credentials)
  - Any application-specific `.env` files for workloads (e.g., API keys, DB URIs)
- **How to provide:**
  - Use Kubernetes secrets or ConfigMaps as appropriate.
  - Reference these in your overlays or base manifests as needed.

---

## Customization
- To add or modify services, update the relevant module in `modules/` and/or the kustomization overlays in `manifests/`.
- Helm values and Terraform variables can be adjusted in `terraform.tfvars` or module-specific variable files.

---

**This repository provides a modular, phased, and customizable approach to managing k3s infrastructure and workloads.**
