# ACM Certificate Outputs

output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate for kriolu-kloud.cv"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
