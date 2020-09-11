module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  #subnets                      = data.aws_subnet_ids.eks_subnets.ids
  subnets                      = module.vpc.private_subnets
  cluster_version              = "${var.eks_version}"
  vpc_id                       = module.vpc.vpc_id
  cluster_iam_role_name        = aws_iam_role.eks_service_role.name
  manage_cluster_iam_resources = false
  tags = {
    Project = "${var.project_id}"
  }
  # windows workaround
  wait_for_cluster_interpreter = ["C:/Users/bprajapati/Desktop/2019/TOOLs/cygwin64/bin/sh.exe", "-c"]
  wait_for_cluster_cmd         = "until curl -sk $ENDPOINT >/dev/null; do sleep 4; done"
  #wait_for_cluster_cmd = "${var.wait_for_cluster_cmd}" # "until wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null; do sleep 4; done"

  #workers_group = [
  /*worker_groups = [
    {
      name          = "worker-group-1"
      instance_type = "t2.small"
      role_arn      = aws_iam_role.eks_service_role.arn
      key_name      = "devops"
      #additional_userdata           = "echo foo bar"
      asg_desired_capacity = 1
      additional_security_group_ids = [
        aws_security_group.worker_group_mgmt_one.id,
        aws_security_group.main_security_group.id,
      ]
    },
  ]
  */

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {

    node_group_one = {
      name                      = "${local.cluster_name}-NG-1"
      ami_type                  = "AL2_x86_64"
      disk_size                 = 30
      desired_capacity          = 1
      max_capacity              = 1
      min_capacity              = 1
      iam_role_arn              = aws_iam_role.eks_ng_role.arn
      instance_type             = "${var.eks_intance_type_main}"
      key_name                  = "${var.node_ssh_key}"
      source_security_group_ids = [aws_security_group.main_security_group.id, aws_security_group.worker_group_mgmt_one.id]
      subnets                   = data.aws_subnet_ids.eks_subnets_private.ids
      additional_tags = {
        Name = "${local.cluster_name}-NG-1"
      }
      k8s_labels = {
        NodeGroupName = "${local.cluster_name}-NG-1"
        lifecycle     = "primary-nodes"
        intent        = "main"
      }
    },

    node_group_two = {
      name                      = "${local.cluster_name}-NG-2"
      ami_type                  = "AL2_x86_64"
      disk_size                 = 30
      desired_capacity          = 1
      max_capacity              = 1
      min_capacity              = 1
      iam_role_arn              = aws_iam_role.eks_ng_role.arn
      instance_type             = "t3.xlarge"
      key_name                  = "devops"
      source_security_group_ids = [aws_security_group.main_security_group.id, aws_security_group.worker_group_mgmt_one.id]
      subnets                   = data.aws_subnet_ids.eks_subnets_private.ids
      additional_tags = {
        Name = "${local.cluster_name}-NG-2"
      }
      k8s_labels = {
        NodeGroupName = "${local.cluster_name}-NG-2"
        lifecycle     = "second-nodes"
        intent        = "secondary"
        Name          = "${local.cluster_name}-NG-2"
      }
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_subnet_ids" "eks_subnets_public" {
  vpc_id = module.vpc.vpc_id
  tags = {
    type = "public"
  }
  depends_on = [
    module.vpc.private_subnets,
    module.vpc.public_subnets,
  ]
}

data "aws_subnet_ids" "eks_subnets_private" {
  vpc_id = module.vpc.vpc_id
  tags = {
    type = "private"
  }
  depends_on = [
    module.vpc.private_subnets,
    module.vpc.public_subnets,
  ]
}

data "aws_subnet_ids" "eks_subnets" {
  vpc_id = module.vpc.vpc_id

  depends_on = [
    module.vpc.private_subnets,
    module.vpc.public_subnets,
  ]
}

########## Creating EKS Node Groups ############  eks_node_groups.aws_auth_roles,

/*
module "eks_node_groups" {
  source               = "terraform-aws-modules/eks/aws//modules/node_groups"
  cluster_name         = local.cluster_name
  default_iam_role_arn = aws_iam_role.eks_ng_role.arn
  create_eks           = false

  node_groups_defaults = {
    name             = "${local.cluster_name}-NG-1"
    ami_type         = "AL2_x86_64"
    disk_size        = 30
    desired_capacity = 1
    max_capacity     = 1
    min_capacity     = 1
    iam_role_arn     = aws_iam_role.eks_ng_role.arn
    instance_type    = "t3.small"
    k8s_labels = {
      NodeGroupName = "${local.cluster_name}-NG-1"
      lifecycle     = "primary-nodes"
      intent        = "main"
    }
    key_name                  = "devops"
    source_security_group_ids = [aws_security_group.main_security_group.id, aws_security_group.worker_group_mgmt_one.id]
    subnets                   = data.aws_subnet_ids.eks_subnets_private.ids
  }

  tags = {
    Name = "${local.cluster_name}-NG-1"
  }

  workers_group_defaults = [
    {
      name          = "worker-group-from-node"
      instance_type = "t2.small"
      role_arn      = aws_iam_role.eks_service_role.arn
      key_name      = "devops"
      #additional_userdata           = "echo foo bar"
      asg_desired_capacity = 1
      additional_security_group_ids = [
        aws_security_group.worker_group_mgmt_one.id,
        aws_security_group.main_security_group.id,
      ]
    },
  ]
}

*/

/*  Creating Node Group Without Module eks

resource "aws_eks_node_group" "eks_node_group_1" {
  cluster_name    = local.cluster_name
  node_group_name = "${local.cluster_name}-NG-1"
  node_role_arn   = aws_iam_role.eks_ng_role.arn
  subnet_ids      = data.aws_subnet_ids.eks_subnets_private.ids
  ami_type        = "AL2_x86_64"
  disk_size       = 30
  labels = {
    NodeGroupName = "${local.cluster_name}-NG-1"
    lifecycle     = "primary-nodes"
    intent        = "main"
  }

  remote_access {
    ec2_ssh_key               = "devops"
    source_security_group_ids = [aws_security_group.main_security_group.id]
  }
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.policy-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.policy-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.policy-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.policy-AmazonSSMFullAccess,
  ]
}
*/
