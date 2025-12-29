# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# SES Domain Identity
# ------------------------------------------------------------------------------
resource "aws_ses_domain_identity" "this" {
  domain = var.domain_name
}

# ------------------------------------------------------------------------------
# Route53 Domain Verification Record
# ------------------------------------------------------------------------------
resource "aws_route53_record" "ses_verification" {
  zone_id = var.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

# Domain verification (wait for DNS propagation)
resource "aws_ses_domain_identity_verification" "this" {
  domain = aws_ses_domain_identity.this.id

  depends_on = [aws_route53_record.ses_verification]
}

# ------------------------------------------------------------------------------
# DKIM (DomainKeys Identified Mail)
# ------------------------------------------------------------------------------
resource "aws_ses_domain_dkim" "this" {
  count  = var.enable_dkim ? 1 : 0
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "dkim" {
  count   = var.enable_dkim ? 3 : 0
  zone_id = var.zone_id
  name    = "${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# ------------------------------------------------------------------------------
# MAIL FROM Domain
# ------------------------------------------------------------------------------
resource "aws_ses_domain_mail_from" "this" {
  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = "mail.${var.domain_name}"
}

# MX Record for MAIL FROM domain
resource "aws_route53_record" "mail_from_mx" {
  zone_id = var.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${data.aws_region.current.id}.amazonses.com"]
}

# SPF Record for MAIL FROM domain
resource "aws_route53_record" "mail_from_spf" {
  zone_id = var.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# ------------------------------------------------------------------------------
# Email Address Identities
# ------------------------------------------------------------------------------
resource "aws_ses_email_identity" "this" {
  for_each = toset(var.from_email_addresses)
  email    = each.value
}
