# smb helm release
resource "helm_release" "csi_driver_smb" {
  name       = "csi-driver-smb"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
  chart      = "csi-driver-smb"
  namespace  = "smb-csi-provisioner"
  version = "1.19.1"
}

