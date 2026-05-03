output "alb_sg_id" {
  description = "The ID of the ALB Security Group"
  value       = aws_security_group.alb.id
}

output "ec2_sg_id" {
  description = "The ID of the EC2 Security Group"
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "The ID of the RDS Security Group"
  value       = aws_security_group.rds.id
}
