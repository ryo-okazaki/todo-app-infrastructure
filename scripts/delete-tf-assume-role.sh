#!/bin/bash
# Description:
#   Delete the IAM role and inline policy created for Terraform DNS delegation.
#   Network AWS アカウント（ドメイン管理アカウント）で実行してください。
#
# Usage:
#   delete-tf-delegation-assume-role.sh \
#     --account-id <ACCOUNT_ID> \
#     --profile <AWS_PROFILE>
#
# Required:
#   --account-id <ACCOUNT_ID>
#       AWS Account ID that was allowed to assume the role (for confirmation output)
#
#   --profile <AWS_PROFILE>
#       AWS CLI profile of the domain management account
#
# Optional:
#   --role-name <ROLE_NAME>
#       IAM role name (default: TerraformDNSDelegationRole)
#
#   --policy-name <POLICY_NAME>
#       Inline policy name (default: AllowRecordUpdate)
#
#   -h, --help
#       Show this help message and exit
#
# Example:
#   ./delete-tf-delegation-assume-role.sh \
#     --account-id 999999999999 \
#     --profile domain-admin
#

set -euo pipefail

# defaults
ROLE_NAME="TerraformDNSDelegationRole"
POLICY_NAME="AllowRecordUpdate"

# === args ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account-id)
      ACCOUNT_ID="$2"
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
      sed -n '2,60p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# === required check ===
if [[ -z "${ACCOUNT_ID:-}" || -z "${AWS_PROFILE:-}" ]]; then
  echo "Error: --account-id and --profile are required."
  sed -n '2,60p' "$0"
  exit 1
fi

# === check role existence ===
if aws iam get-role \
     --role-name "${ROLE_NAME}" \
     --profile "${AWS_PROFILE}" \
     >/dev/null 2>&1; then
  echo "🔍 Found IAM role: ${ROLE_NAME}"
else
  echo "ℹ️  IAM role does not exist. Nothing to delete."
  exit 0
fi

# === delete inline policy (if exists) ===
if aws iam get-role-policy \
     --role-name "${ROLE_NAME}" \
     --policy-name "${POLICY_NAME}" \
     --profile "${AWS_PROFILE}" \
     >/dev/null 2>&1; then
  echo "🗑 Deleting inline policy: ${POLICY_NAME}"
  aws iam delete-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${POLICY_NAME}" \
    --profile "${AWS_PROFILE}"
else
  echo "ℹ️  Inline policy does not exist. Skipping."
fi

# === delete role ===
echo "🗑 Deleting IAM role: ${ROLE_NAME}"
aws iam delete-role \
  --role-name "${ROLE_NAME}" \
  --profile "${AWS_PROFILE}"

echo "✅ IAM role deleted successfully:"
echo "   - role name       : ${ROLE_NAME}"
echo "   - allowed account : ${ACCOUNT_ID}"
echo "   - profile         : ${AWS_PROFILE}"
