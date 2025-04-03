variable "name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "juice-shop-cluster"
}

variable "region" {
  type        = string
  description = "AWS region to deploy to"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.123.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = ["10.123.1.0/24", "10.123.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
  default     = ["10.123.3.0/24", "10.123.4.0/24"]
}

variable "intra_subnets" {
  type        = list(string)
  description = "List of intra subnet CIDR blocks"
  default     = ["10.123.5.0/24", "10.123.6.0/24"]
}

variable "image_tag" {
  type        = string
  description = "Docker image tag for the Juice Shop app"
  default     = "juice-shop-app"
}
