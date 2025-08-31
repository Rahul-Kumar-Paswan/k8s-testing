variable "region" {
  type = string
}

# vpc variables
variable "vpc_cidr" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_availability_zones" {
  type = list(string)
}

variable "private_subnet_availability_zones" {
  type = list(string)
}

# ec2 variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name (PEM file)"
  type        = string
}

variable "volume_size" {
  description = "Root volume size (GB)"
  type        = number
}

variable "volume_type" {
  description = "Root volume type"
  type        = string
}

# EKS variables
# variable "eks_cluster_name" {
#   type        = string
#   description = "Name of the EKS cluster"
# }

# variable "eks_version" {
#   type        = string
#   description = "Kubernetes version for EKS cluster"
# }

# variable "desired_worker_count" {
#   type        = number
#   description = "Number of worker nodes"
# }

# variable "min_worker_count" {
#   type        = number
# }

# variable "max_worker_count" {
#   type        = number
# }

# variable "node_instance_type" {
#   type        = string
# }
