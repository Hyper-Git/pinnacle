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
