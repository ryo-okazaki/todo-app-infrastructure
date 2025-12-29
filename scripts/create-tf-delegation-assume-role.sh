#!/bin/bash
# Description:
#   Create an IAM role in the domain management AWS account that allows
#   Network AWS アカウントをprofileにして実行して下さい。
#   terraform実行アカウントには "TerraformDNSDelegationRole" ロールを引き受ける権限が必要です
#
# Usage:
#   create-tf-delegation-assume-role.sh \
#     --account-id <ACCOUNT_ID> [--account-id <ACCOUNT_ID> ...] \
#     --hosted-zone-id <HOSTED_ZONE_ID> \
#     --profile <AWS_PROFILE>

set -euo pipefail

# defaults
ROLE_NAME="TerraformDNSDelegationRole"
POLICY_NAME="AllowRecordUpdate"

# multiple account IDs
ACCOUNT_IDS=()

# === args ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account-id)
      ACCOUNT_IDS+=("$2")
      shift 2
      ;;
    --hosted-zone-id)
      HOSTED_ZONE_ID="$2"
      shift 2
      ;;
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    --role-name)
      ROLE_NAME="$2"
      shift 2
      ;;
    --policy-name)
      POLICY_NAME="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,80p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# === required check ===
if [[ ${#ACCOUNT_IDS[@]} -eq 0 || -z "${HOSTED_ZONE_ID:-}" || -z "${AWS_PROFILE:-}" ]]; then
  echo "Error: --account-id (at least one), --hosted-zone-id, and --profile are required."
  sed -n '2,80p' "$0"
  exit 1
fi

# === build principal ARNs ===
PRINCIPAL_ARNS=()
for id in "${ACCOUNT_IDS[@]}"; do
  PRINCIPAL_ARNS+=( "\"arn:aws:iam::${id}:root\"" )
done

PRINCIPAL_ARNS_JSON=$(IFS=, ; echo "${PRINCIPAL_ARNS[*]}")

# === trust policy ===
TRUST_POLICY_JSON=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          ${PRINCIPAL_ARNS_JSON}
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

# === permission policy ===
PERMISSION_POLICY_JSON=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListHostedZones",
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowGetAndListSpecificZone",
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/Z015764518G1D049IWPT0"
    },
    {
      "Sid": "AllowGetChangeStatus",
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    }
  ]
}
EOF
)

# === create role (idempotent) ===
if aws iam get-role \
     --role-name "${ROLE_NAME}" \
     --profile "${AWS_PROFILE}" \
     >/dev/null 2>&1; then
  echo "ℹ️  Role already exists. Skipping creation: ${ROLE_NAME}"
else
  echo "🆕 Creating IAM role: ${ROLE_NAME}"
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "${TRUST_POLICY_JSON}" \
    --profile "${AWS_PROFILE}"
fi

# === attach inline policy (idempotent) ===
echo "🛡 Applying inline policy: ${POLICY_NAME}"
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "${POLICY_NAME}" \
  --policy-document "${PERMISSION_POLICY_JSON}" \
  --profile "${AWS_PROFILE}"

# === get role ARN ===
ROLE_ARN=$(aws iam get-role \
  --role-name "${ROLE_NAME}" \
  --query 'Role.Arn' \
  --output text \
  --profile "${AWS_PROFILE}")

# === final output ===
echo "✅ IAM role is ready for DNS delegation:"
echo "   - role name       : ${ROLE_NAME}"
echo "   - role arn        : ${ROLE_ARN}"
echo "   - allowed accounts:"
for id in "${ACCOUNT_IDS[@]}"; do
  echo "       - ${id}"
done
echo "   - hosted zone id  : ${HOSTED_ZONE_ID}"
echo "   - profile         : ${AWS_PROFILE}"
