output "cluster_name" {

  value = module.eks.cluster_name

}

output "cluster_endpoint" {

  value = module.eks.cluster_endpoint

}

output "vpc_id" {

  value = module.vpc.vpc_id

}

output "ecr_repository_url" {

  value = aws_ecr_repository.bluegreen_repo.repository_url

}