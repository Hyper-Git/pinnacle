variable "project" {
  description = "Project name, used as prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on (ALB → EC2 traffic)"
  type        = number
  default     = 80
}

variable "github_repo" {
  description = "GitHub repository for OIDC trust policy (format: owner/repo)"
  type        = string
}

variable "deployment_bucket_name" {
  description = "S3 bucket name for application deployment artifacts"
  type        = string
  default     = "pinnacle-deployments"
}
