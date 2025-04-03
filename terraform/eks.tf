module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = var.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "BOTTLEROCKET_ARM_64"
    instance_types = ["t4g.medium"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    juice-shop-br = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t4g.medium"]
      capacity_type  = "SPOT"

      tags = {
        Name    = "juice-shop-arm64"
        Project = "juice-shop"
        OS      = "Bottlerocket"
        Arch    = "ARM64"
      }
    }
  }
}
