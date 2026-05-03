variable "project" {
  description = "Project name, used as prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (one per AZ)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ASG (one per AZ)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "IAM instance profile name to attach to the launch template"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the A alias record"
  type        = string
}

variable "fqdn" {
  description = "Fully qualified domain name for the Route 53 A record (e.g. pinnacle.cornelcloud.net)"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials — fetched by user data on boot"
  type        = string
}

variable "deployment_bucket_name" {
  description = "S3 bucket name for application deployment artifacts"
  type        = string
  default     = "pinnacle-deployments"
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the application and target group listen on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path the ALB uses to health check instances"
  type        = string
  default     = "/health"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}
