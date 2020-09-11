
resource "aws_efs_file_system" "aws_efs" {

  encrypted        = true
  performance_mode = "generalPurpose"

  tags = {
    Name = "${local.cluster_name}-EFS"
  }
}


/*
resource "kubernetes_storage_class" "efs_sc" {

  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "efs-primary-volume" {

  metadata {
    name = "efs-primary-volume"
    labels = {
      type = "local"
    }
  }

  spec {
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class.efs_sc.metadata[0].name

  }

}
*/