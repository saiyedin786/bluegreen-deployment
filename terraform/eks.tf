module "eks" {

  source = "terraform-aws-modules/eks/aws"

  version = "20.15.0"

  cluster_name = var.cluster_name

  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  subnet_ids = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  eks_managed_node_groups = {

    default = {

      desired_size = 2

      min_size = 2

      max_size = 3

      instance_types = [var.node_instance_type]

      capacity_type = "ON_DEMAND"

    }

  }

}