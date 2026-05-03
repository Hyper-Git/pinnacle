variable "project" {
  description = "Project name, used as prefix in resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name — used as CloudWatch dimension for EC2 alarms"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix — used as CloudWatch dimension for ALB alarms"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix — used as CloudWatch dimension for ALB alarms"
  type        = string
}

variable "db_identifier" {
  description = "RDS instance identifier — used as CloudWatch dimension for RDS alarms"
  type        = string
}
