#!/bin/bash
timestamp=$(date +"%Y%m%d")
BACKUP_ZIP="k3s-infra-secret-files-${timestamp}.zip"
zip -r $BACKUP_ZIP terraform.tfvars manifests/overlays/env_files terraform.tfstate terraform.tfstate.backup
mv $BACKUP_ZIP $IAC_BACKUP_LOC
echo "Backup completed: $BACKUP_ZIP copied to $IAC_BACKUP_LOC"
