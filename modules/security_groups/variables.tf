variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "app_port" {
  description = "The port the application listens on"
  type        = number
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "app"
}
