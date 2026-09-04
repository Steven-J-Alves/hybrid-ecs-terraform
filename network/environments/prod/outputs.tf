output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate for kriolu-kloud.cv"
  value       = module.vpc_hybrid.acm_certificate_arn
}
