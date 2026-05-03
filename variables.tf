variable "project" {
  description = "Project name, used as prefix in all resource names"
  type        = string
  default     = "pinnacle"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Root domain name of the existing Route 53 hosted zone (e.g. cornelcloud.net)"
  type        = string
  default     = "cornelcloud.net"
}

variable "subdomain" {
  description = "Subdomain to issue the ACM certificate for (e.g. pinnacle)"
  type        = string
  default     = "pinnacle"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository for OIDC trust policy (format: owner/repo)"
  type        = string
  default     = "Hyper-Git/pinnacle"
}
