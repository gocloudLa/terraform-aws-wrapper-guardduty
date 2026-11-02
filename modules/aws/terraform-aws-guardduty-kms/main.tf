data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowGuardDutyEncryptFindings"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey"]
    resources = ["*"]
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
    sid    = "AllowLogsAccountDecryptFindings"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.log_account_id}:root"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.log_account_id]
    }
  }

  # SSE-KMS calls KMS with the credentials of the principal writing to the bucket (not the S3 service principal),
  # so log-account principals need encrypt permissions through S3 (e.g. the prefix object created by Terraform).
  statement {
    sid    = "AllowLogsAccountUseKeyViaS3"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.log_account_id}:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.log_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.log_region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.kms.json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = var.alias_name
  target_key_id = aws_kms_key.this.key_id
}
