variable "project" {
  description = "Project name, used as prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository for the OIDC trust policy (format: owner/repo)"
  type        = string
}

variable "deployment_bucket_name" {
  description = "S3 deployment bucket name — scopes the S3 write permission"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name — scopes the StartInstanceRefresh permission"
  type        = string
}
