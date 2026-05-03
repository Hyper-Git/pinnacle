variable "project" {
  description = "Project name, used for tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment, used for tagging"
  type        = string
}

variable "domain_name" {
  description = "Root domain name of the existing Route 53 hosted zone (e.g. cornelcloud.net)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain to create the ACM certificate for (e.g. pinnacle)"
  type        = string
}
