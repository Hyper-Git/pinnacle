output "certificate_arn" {
  description = "ARN of the validated ACM certificate for the subdomain"
  # Reference the validation resource so consumers implicitly depend on the cert being ISSUED
  value = aws_acm_certificate_validation.main.certificate_arn
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the root domain"
  value       = data.aws_route53_zone.main.zone_id
}

output "fqdn" {
  description = "Fully qualified domain name the certificate is issued for"
  value       = local.fqdn
}
