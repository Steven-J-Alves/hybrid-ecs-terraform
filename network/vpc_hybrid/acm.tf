# ACM Wildcard Certificate for kriolu-kloud.cv
# Managed here in the network stack so a destroy+recreate from scratch works
# without manual pre-provisioning. The cluster and apps stacks consume the cert
# via data "aws_acm_certificate" (by domain name) — no changes needed there.

# ---------------------------------------------------------------------------
# Route53 hosted zone (data source — zone was created outside Terraform)
# ---------------------------------------------------------------------------
data "aws_route53_zone" "public" {
  name = "kriolu-kloud.cv."
}

# ---------------------------------------------------------------------------
# Wildcard certificate
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "main" {
  domain_name               = "*.kriolu-kloud.cv"
  subject_alternative_names = ["kriolu-kloud.cv"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# DNS validation records — one record per domain_validation_options entry
# ---------------------------------------------------------------------------
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public.zone_id
}

# ---------------------------------------------------------------------------
# Validation waiter — blocks apply until ACM marks the cert ISSUED
# ---------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
