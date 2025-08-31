
variable "environment" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for security group"
}

variable "instance_type" {
  type        = string
}

variable "key_name" {
  type        = string
  description = "AWS key pair name"
}

variable "volume_size" {
  type        = number
}

variable "volume_type" {
  type        = string
}
