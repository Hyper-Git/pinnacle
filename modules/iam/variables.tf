variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "app"
}

variable "config_bucket_arn" {
  description = "ARN of the S3 bucket containing app config"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  type        = string
}
