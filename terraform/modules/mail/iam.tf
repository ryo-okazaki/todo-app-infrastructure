# ------------------------------------------------------------------------------
# IAM Policy Document
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "ses_send_email" {
  # Basic send email permissions
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      aws_ses_domain_identity.this.arn,
      "arn:aws:ses:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:identity/${var.domain_name}"
    ]
  }

  # Individual email identities
  dynamic "statement" {
    for_each = length(var.from_email_addresses) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = [
        for email in var.from_email_addresses :
        "arn:aws:ses:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:identity/${email}"
      ]
    }
  }

  # Configuration Set permissions
  dynamic "statement" {
    for_each = var.enable_configuration_set ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = [
        aws_ses_configuration_set.this[0].arn
      ]
    }
  }
}

# ------------------------------------------------------------------------------
# IAM Policy
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "ses_send_email" {
  name        = "${replace(var.domain_name, ".", "-")}-ses-send-email"
  description = "Allow sending email via SES for ${var.domain_name}"
  policy      = data.aws_iam_policy_document.ses_send_email.json

  tags = {
    Name = "${var.domain_name}-ses-send-email"
  }
}
