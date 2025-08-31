# ==========================
# VPC Outputs
# ==========================
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# ==========================
# EC2 Outputs
# ==========================
output "sonarqube_instance_id" {
  value = module.ec2_instances.sonarqube_id
}

output "sonarqube_public_ip" {
  value = module.ec2_instances.sonarqube_public_ip
}

output "sonarqube_private_ip" {
  value = module.ec2_instances.sonarqube_private_ip
}

output "nexus_instance_id" {
  value = module.ec2_instances.nexus_id
}

output "nexus_public_ip" {
  value = module.ec2_instances.nexus_public_ip
}

output "nexus_private_ip" {
  value = module.ec2_instances.nexus_private_ip
}

# ==========================
# EKS Outputs
# ==========================
output "eks_cluster_name" {
  value = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.eks_cluster_endpoint
}

output "eks_cluster_arn" {
  value = module.eks.eks_cluster_arn
}

output "node_group_name" {
  value = module.eks.node_group_name
}
