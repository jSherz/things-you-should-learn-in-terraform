locals {
  cloudtrail_bucket = "${var.bucket_name}-cloudtrail"
  cloudtrail_trail  = "s3-${var.bucket_name}"
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck20150319"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${local.cloudtrail_bucket}"]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:trail/${local.cloudtrail_trail}"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite20150319"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${local.cloudtrail_bucket}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:trail/${local.cloudtrail_trail}"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

module "cloudtrail_bucket" {
  source = "../s3-bucket"

  name   = "${var.bucket_name}-cloudtrail"
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudtrail" "main" {
  name           = "s3-${var.bucket_name}"
  s3_bucket_name = module.cloudtrail_bucket.name

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.bucket_name}/"]
    }
  }

  # Ensure the whole module has been created as we require the aws_s3_bucket_policy resource
  depends_on = [module.cloudtrail_bucket]
}
