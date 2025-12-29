# ------------------------------------------------------------------------------
# SNS Topic
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "ses_notifications" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = var.sns_topic_name != null ? var.sns_topic_name : "${replace(var.domain_name, ".", "-")}-ses-notifications"

  tags = {
    Name = var.sns_topic_name != null ? var.sns_topic_name : "${var.domain_name}-ses-notifications"
  }
}

# ------------------------------------------------------------------------------
# SNS Topic Policy
# ------------------------------------------------------------------------------
resource "aws_sns_topic_policy" "ses_notifications" {
  count  = var.enable_sns_notifications ? 1 : 0
  arn    = aws_sns_topic.ses_notifications[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.enable_sns_notifications ? 1 : 0

  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [aws_sns_topic.ses_notifications[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# ------------------------------------------------------------------------------
# Identity Notification Topics
# ------------------------------------------------------------------------------

# Bounce Notifications
resource "aws_ses_identity_notification_topic" "bounce" {
  count                    = var.enable_sns_notifications ? 1 : 0
  topic_arn                = aws_sns_topic.ses_notifications[0].arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = true
}

# Complaint Notifications
resource "aws_ses_identity_notification_topic" "complaint" {
  count                    = var.enable_sns_notifications ? 1 : 0
  topic_arn                = aws_sns_topic.ses_notifications[0].arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = true
}

# Delivery Notifications
resource "aws_ses_identity_notification_topic" "delivery" {
  count                    = var.enable_sns_notifications ? 1 : 0
  topic_arn                = aws_sns_topic.ses_notifications[0].arn
  notification_type        = "Delivery"
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = false
}
