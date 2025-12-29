output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    for k, v in aws_ecr_repository.this : k => v.repository_url
  }
}

output "logs_bucket" {
  description = "Logs S3 bucket info"
  value = {
    id                          = aws_s3_bucket.logs.id
    arn                         = aws_s3_bucket.logs.arn
    bucket_domain_name          = aws_s3_bucket.logs.bucket_domain_name
    bucket_regional_domain_name = aws_s3_bucket.logs.bucket_regional_domain_name
  }
}
