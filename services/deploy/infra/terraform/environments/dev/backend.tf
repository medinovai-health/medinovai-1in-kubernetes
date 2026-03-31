# -----------------------------------------------------------------------------
# Terraform backend - S3 with DynamoDB lock
# -----------------------------------------------------------------------------
# Before first use: create the S3 bucket and DynamoDB table, then
# replace ACCOUNT and REGION with your AWS account ID and region.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "medinovai-terraform-state-ACCOUNT-REGION"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "medinovai-terraform-lock"
    encrypt        = true
  }
}
