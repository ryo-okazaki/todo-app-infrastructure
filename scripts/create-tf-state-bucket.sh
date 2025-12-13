#!/bin/bash
#
# Usage:
#   create-tf-state-bucket.sh --bucket <S3_BUCKET_NAME> --id <AWS_ACCOUNT_ID> --profile <AWS_PROFILE> [options]
#
# Required:
#   --bucket <S3_BUCKET_NAME>
#       Name of the S3 bucket used for Terraform remote state
#
#   --id <AWS_ACCOUNT_ID>
#       AWS Account ID allowed to access the bucket (root principal)
#
#   --profile <AWS_PROFILE>
#       AWS CLI profile to use (default: default)
#
# Optional:
#   --region <AWS_REGION>
#       AWS region (default: ap-northeast-1)
#
#   -h, --help
#       Show this help message and exit
#
# Example:
#   ./create-tf-state-bucket.sh \
#     --bucket develop.todo-app.tf-state-bucket \
#     --id 123456789012 \
#     --region ap-northeast-1 \
#     --profile shared-admin
#

set -euo pipefail

# defaults
AWS_PROFILE="default"
AWS_REGION="ap-northeast-1"

# === args ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bucket)
      BUCKET_NAME="$2"
      shift 2
      ;;
    --id)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,50p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# === required check ===
if [[ -z "${BUCKET_NAME:-}" || -z "${ACCOUNT_ID:-}" ]]; then
  echo "Error: --bucket and --id are required."
  sed -n '2,50p' "$0"
  exit 1
fi

# === check bucket existence ===
if aws s3api head-bucket \
     --bucket "${BUCKET_NAME}" \
     --profile "${AWS_PROFILE}" 2>/dev/null; then
  echo "ℹ️  Bucket already exists. Skipping creation: ${BUCKET_NAME}"
else
  echo "🆕 Creating bucket: ${BUCKET_NAME}"
  aws s3 mb "s3://${BUCKET_NAME}" \
    --region "${AWS_REGION}" \
    --profile "${AWS_PROFILE}"
fi

# === enable versioning ===
echo "🔧 Ensuring versioning is enabled"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  --profile "${AWS_PROFILE}"

# === enable SSE ===
echo "🔐 Ensuring server-side encryption is enabled (AES256)"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile "${AWS_PROFILE}"

# === bucket policy ===
echo "🛡 Applying bucket policy"

POLICY_JSON=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ]
    }
  ]
}
EOF
)

aws s3api put-bucket-policy \
  --bucket "${BUCKET_NAME}" \
  --policy "${POLICY_JSON}" \
  --profile "${AWS_PROFILE}"

echo "✅ Terraform state bucket is fully configured:"
echo "   - bucket : ${BUCKET_NAME}"
echo "   - region : ${AWS_REGION}"
echo "   - profile: ${AWS_PROFILE}"
echo "   - allowed account: ${ACCOUNT_ID}"
