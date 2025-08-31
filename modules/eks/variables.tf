# variable "environment" {
#   type = string
# }

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version for EKS cluster"
}

variable "desired_worker_count" {
  type        = number
  description = "Number of worker nodes"
}

variable "min_worker_count" {
  type        = number
}

variable "max_worker_count" {
  type        = number
}

variable "node_instance_type" {
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}