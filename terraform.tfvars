project_id   = "devops-tools"
env_type = "dev"

# EKS Config
eks_version              = "1.16"
eks_intance_type_main    = "t2.small"
eks_cluster_main_ng_size = 2

vpc_cidr = "10.0.0.0/16"

public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
node_ssh_key = "smartparking"
