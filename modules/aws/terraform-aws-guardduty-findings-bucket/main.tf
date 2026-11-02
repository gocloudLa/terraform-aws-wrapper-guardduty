resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

data "aws_iam_policy_document" "guardduty" {
  statement {
    sid    = "AllowGuardDutyGetBucketLocation"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.this.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.sec_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = var.detector_arns
    }
  }

  statement {
    sid    = "AllowGuardDutyPutObject"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/${local.prefix_with_slash}*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.sec_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = var.detector_arns
    }
  }

  # With a key prefix, CreatePublishingDestination verifies the prefix exists (s3:GetObject / s3:ListBucket).
  dynamic "statement" {
    for_each = length(local.prefix_with_slash) > 0 ? [1] : []
    content {
      sid    = "AllowGuardDutyPrefixCheck"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["guardduty.amazonaws.com"]
      }
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/${local.prefix_with_slash}*",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [var.sec_account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = var.detector_arns
      }
    }
  }

  # The prefix check can also run with the caller's credentials (delegated admin account principal).
  dynamic "statement" {
    for_each = length(local.prefix_with_slash) > 0 ? [1] : []
    content {
      sid    = "AllowDelegatedAdminPrefixCheck"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.sec_account_id}:root"]
      }
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/${local.prefix_with_slash}*",
      ]
    }
  }

  statement {
    sid    = "DenyGuardDutyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/${local.prefix_with_slash}*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid    = "DenyGuardDutyIncorrectEncryptionHeader"
    effect = "Deny"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/${local.prefix_with_slash}*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.guardduty.json

  depends_on = [
    aws_s3_bucket_public_access_block.this,
  ]
}

# GuardDuty does not create the destination prefix; the "folder" must exist before the publishing destination is created.
resource "aws_s3_object" "prefix" {
  count = length(local.prefix_with_slash) > 0 ? 1 : 0

  bucket                 = aws_s3_bucket.this.id
  key                    = local.prefix_with_slash
  content                = ""
  server_side_encryption = "aws:kms"
  kms_key_id             = var.kms_key_arn

  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.this,
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.has_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "guardduty-findings-lifecycle"
    status = "Enabled"
    filter {}

    dynamic "transition" {
      for_each = var.lifecycle_glacier_transition_days != null ? [1] : []
      content {
        days          = var.lifecycle_glacier_transition_days
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.lifecycle_expiration_days != null ? [1] : []
      content {
        days = var.lifecycle_expiration_days
      }
    }
  }
}
