output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB — used in CloudWatch metric dimensions"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group — used in CloudWatch metric dimensions"
  value       = aws_lb_target_group.main.arn_suffix
}

output "asg_name" {
  description = "Auto Scaling Group name — used by CI/CD to trigger instance refresh"
  value       = aws_autoscaling_group.main.name
}

output "deployment_bucket_name" {
  description = "S3 deployment bucket name"
  value       = aws_s3_bucket.deployments.bucket
}
