# ------------------------------------------------------------------------------
# Configuration Set
# ------------------------------------------------------------------------------
resource "aws_ses_configuration_set" "this" {
  count = var.enable_configuration_set ? 1 : 0
  name  = var.configuration_set_name != null ? var.configuration_set_name : "${replace(var.domain_name, ".", "-")}-config-set"

  reputation_metrics_enabled = true
  sending_enabled            = true

  delivery_options {
    tls_policy = "Require"
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Event Destination
# ------------------------------------------------------------------------------
resource "aws_ses_event_destination" "cloudwatch" {
  count                  = var.enable_configuration_set ? 1 : 0
  name                   = "cloudwatch-events"
  configuration_set_name = aws_ses_configuration_set.this[0].name
  enabled                = true
  matching_types = [
    "send",
    "reject",
    "bounce",
    "complaint",
    "delivery",
    "open",
    "click",
    "renderingFailure"
  ]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}
