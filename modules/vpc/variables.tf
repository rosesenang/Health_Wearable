# modules/vpc/variables.tf

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create"
  default     = 2
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create"
  default     = 2
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones for subnet placement"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project_name" {
  type        = string
  description = "Project name for tagging resources"
}

