# ── DNS + TLS (prerequisite for compute) ─────────────────────────────────────

output "certificate_arn" {
  description = "ARN of the validated ACM certificate for the ALB HTTPS listener"
  value       = module.dns.certificate_arn
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for cornelcloud.net"
  value       = module.dns.hosted_zone_id
}

output "fqdn" {
  description = "Fully qualified domain name (pinnacle.cornelcloud.net)"
  value       = module.dns.fqdn
}

# ── Phase 1: Networking ───────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (one per AZ)"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

# ── Phase 2: Security ─────────────────────────────────────────────────────────

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = module.security.ec2_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.security.rds_security_group_id
}

output "ec2_instance_profile_name" {
  description = "EC2 IAM instance profile name"
  value       = module.security.ec2_instance_profile_name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = module.security.github_actions_role_arn
}

# ── Phase 3: Database ─────────────────────────────────────────────────────────

output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = module.database.db_secret_arn
}

output "db_identifier" {
  description = "RDS instance identifier"
  value       = module.database.db_identifier
}

# ── Phase 4: Compute ──────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "ALB DNS name — also reachable via pinnacle.cornelcloud.net"
  value       = module.compute.alb_dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metric dimensions"
  value       = module.compute.alb_arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch metric dimensions"
  value       = module.compute.target_group_arn_suffix
}

output "asg_name" {
  description = "Auto Scaling Group name for CI/CD instance refresh"
  value       = module.compute.asg_name
}

output "deployment_bucket_name" {
  description = "S3 deployment bucket name"
  value       = module.compute.deployment_bucket_name
}
