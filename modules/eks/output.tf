output "eks_cluster_name" {
  value = aws_eks_cluster.rahulverse_eks.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.rahulverse_eks.endpoint
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.rahulverse_eks.arn
}

output "node_group_name" {
  value = aws_eks_node_group.worker_nodes.node_group_name
}
