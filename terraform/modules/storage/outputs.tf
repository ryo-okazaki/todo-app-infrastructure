output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "s3_logs_bucket_id" {
  description = "Logs bucket ID"
  value       = aws_s3_bucket.logs.id
}

output "s3_assets_bucket_id" {
  description = "Assets bucket ID"
  value       = aws_s3_bucket.assets.id
}

output "s3_assets_bucket_arn" {
  description = "Assets bucket ARN (for CloudFront policy)"
  value       = aws_s3_bucket.assets.arn
}
