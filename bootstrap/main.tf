
#provider, data.aws_caller_identity
#state 버킷 3종
terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

#S3 버킷
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  lifecycle {
    prevent_destroy = true
  }
}

#버전 관리
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

#퍼블릭 엑세스 차단
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}