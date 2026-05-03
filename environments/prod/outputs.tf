output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}

output "alb_sg_id" {
  value = module.security_groups.alb_sg_id
}

output "ec2_sg_id" {
  value = module.security_groups.ec2_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}

output "ec2_instance_profile" {
  value = module.iam.instance_profile_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_secret_arn" {
  value = module.rds.secret_arn
}
