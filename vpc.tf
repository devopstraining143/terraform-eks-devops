data "aws_availability_zones" "available" {}

locals {
  #cluster_name = "${var.cluster_name}-eks-${random_string.suffix.result}"
  cluster_name = "${var.project_id}-${var.env_type}-EKS-Cluster"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "${var.project_id}-VPC"
  cidr                 = "${var.vpc_cidr}"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = "${var.public_subnets}"
  public_subnets       = "${var.private_subnets}"
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "type"                                        = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "type"                                        = "private"
  }
}

