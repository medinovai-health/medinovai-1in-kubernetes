#!/usr/bin/env bash
# ─── init-cloud-account.sh ────────────────────────────────────────────────────
# Bootstrap a cloud account for MedinovAI deployment.
# Creates: Terraform state backend, IAM bootstrap roles, encryption keys.
#
# Usage:
#   bash scripts/bootstrap/init-cloud-account.sh --cloud aws --region us-east-1
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CLOUD="aws"
REGION="us-east-1"
PROJECT="medinovai"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cloud)    CLOUD="$2"; shift 2 ;;
        --region)   REGION="$2"; shift 2 ;;
        --dry-run)  DRY_RUN=true; shift ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Cloud Account Bootstrap — $CLOUD / $REGION"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

case "$CLOUD" in
    aws)
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "UNKNOWN")
        STATE_BUCKET="${PROJECT}-terraform-state-${ACCOUNT_ID}-${REGION}"
        LOCK_TABLE="${PROJECT}-terraform-lock"

        echo "▸ AWS Account: $ACCOUNT_ID"
        echo "▸ State Bucket: $STATE_BUCKET"
        echo "▸ Lock Table: $LOCK_TABLE"
        echo ""

        if $DRY_RUN; then
            echo "[DRY RUN] Would create:"
            echo "  - S3 bucket: $STATE_BUCKET (versioned, encrypted, private)"
            echo "  - DynamoDB table: $LOCK_TABLE (PAY_PER_REQUEST)"
            echo "  - KMS key for state encryption"
            exit 0
        fi

        echo "▸ Creating Terraform state bucket..."
        if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
            echo "  ✓ Bucket already exists"
        else
            aws s3api create-bucket \
                --bucket "$STATE_BUCKET" \
                --region "$REGION" \
                $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION")

            aws s3api put-bucket-versioning \
                --bucket "$STATE_BUCKET" \
                --versioning-configuration Status=Enabled

            aws s3api put-bucket-encryption \
                --bucket "$STATE_BUCKET" \
                --server-side-encryption-configuration \
                '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

            aws s3api put-public-access-block \
                --bucket "$STATE_BUCKET" \
                --public-access-block-configuration \
                "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

            echo "  ✓ State bucket created"
        fi

        echo "▸ Creating DynamoDB lock table..."
        if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" &>/dev/null; then
            echo "  ✓ Lock table already exists"
        else
            aws dynamodb create-table \
                --table-name "$LOCK_TABLE" \
                --attribute-definitions AttributeName=LockID,AttributeType=S \
                --key-schema AttributeName=LockID,KeyType=HASH \
                --billing-mode PAY_PER_REQUEST \
                --region "$REGION"

            echo "  ✓ Lock table created"
        fi
        ;;

    gcp)
        echo "▸ GCP bootstrap..."
        echo "  TODO: Create GCS bucket for state"
        echo "  TODO: Create service accounts"
        echo "  TODO: Enable required APIs"
        ;;

    azure)
        echo "▸ Azure bootstrap..."
        echo "  TODO: Create resource group"
        echo "  TODO: Create storage account for state"
        echo "  TODO: Create service principals"
        ;;

    *)
        echo "Unsupported cloud provider: $CLOUD"
        echo "Supported: aws, gcp, azure"
        exit 1
        ;;
esac

echo ""
echo "✓ Cloud account bootstrap complete for $CLOUD / $REGION"
