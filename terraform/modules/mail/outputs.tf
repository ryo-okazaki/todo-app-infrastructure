output "domain_identity_arn" {
  description = "SES Domain Identity ARN"
  value       = aws_ses_domain_identity.this.arn
}

output "domain_identity_verification_token" {
  description = "Domain verification token"
  value       = aws_ses_domain_identity.this.verification_token
  sensitive   = true
}

output "mail_from_domain" {
  description = "MAIL FROM domain"
  value       = aws_ses_domain_mail_from.this.mail_from_domain
}

output "dkim_tokens" {
  description = "DKIM tokens for DNS verification"
  value       = var.enable_dkim ? aws_ses_domain_dkim.this[0].dkim_tokens : []
  sensitive   = true
}

output "configuration_set_name" {
  description = "SES Configuration Set name"
  value       = var.enable_configuration_set ? aws_ses_configuration_set.this[0].name : null
}

output "configuration_set_arn" {
  description = "SES Configuration Set ARN"
  value       = var.enable_configuration_set ? aws_ses_configuration_set.this[0].arn : null
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for notifications"
  value       = var.enable_sns_notifications ? aws_sns_topic.ses_notifications[0].arn : null
}

output "iam_policy_arn" {
  description = "IAM Policy ARN for sending emails"
  value       = aws_iam_policy.ses_send_email.arn
}

output "verified_email_addresses" {
  description = "List of verified email addresses"
  value       = [for email in aws_ses_email_identity.this : email.email]
}

output "smtp_endpoint" {
  description = "SES SMTP endpoint"
  value       = "email-smtp.${data.aws_region.current.id}.amazonaws.com"
}

output "smtp_port" {
  description = "SES SMTP port (TLS)"
  value       = 587
}
