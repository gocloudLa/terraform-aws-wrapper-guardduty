# One organization configuration per Region; key = AWS Region.
resource "aws_guardduty_organization_configuration" "this" {
  for_each = var.detectors

  region                           = each.key
  detector_id                      = each.value.id
  auto_enable_organization_members = var.auto_enable_organization_members

  lifecycle {
    precondition {
      condition     = var.delegated_admin_account_id != var.management_account_id
      error_message = "aws.sec must point to the GuardDuty delegated administrator account, not the Organizations management account."
    }
    precondition {
      condition     = contains(keys(var.detectors), var.home_region)
      error_message = "guardduty_parameters.regions must include the home Region (aws.sec provider Region)."
    }
  }
}

# One protection plan per Region and feature; key = "<region>-<feature>" (e.g. "us-east-1-S3_DATA_EVENTS").
resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each = local.features

  region      = each.value.region
  detector_id = each.value.detector_id
  name        = each.value.name
  auto_enable = each.value.auto_enable

  dynamic "additional_configuration" {
    for_each = each.value.additional_configuration
    content {
      name        = additional_configuration.value.name
      auto_enable = additional_configuration.value.auto_enable
    }
  }

  depends_on = [aws_guardduty_organization_configuration.this]
}

# auto_enable_organization_members does not cover the management account. AWS requires a detector there before
# the delegated administrator can add it as a member; once a member, the organization features apply to it.
# Key: AWS Region.
resource "aws_guardduty_detector" "management" {
  for_each = var.enable_management_account ? var.detectors : {}
  provider = aws.org

  region = each.key

  tags = var.tags
}

# GuardDuty takes a while to register a new detector; CreateMembers fails until then ("your organization master must
# first enable GuardDuty"). Only delays the first deploy. Key: AWS Region.
resource "time_sleep" "management_detector" {
  for_each = aws_guardduty_detector.management

  create_duration = "30s"

  triggers = {
    account_id = each.value.account_id
  }
}

# Key: AWS Region.
resource "aws_guardduty_member" "management" {
  for_each = var.enable_management_account ? var.detectors : {}

  region                     = each.key
  detector_id                = each.value.id
  account_id                 = time_sleep.management_detector[each.key].triggers["account_id"]
  email                      = var.management_account_email
  invite                     = false
  disable_email_notification = true

  lifecycle {
    # Only used on creation: AWS does not store them for organization accounts, so the provider reads invite as true
    # once the member is Enabled and email as empty (email forces replacement).
    ignore_changes = [invite, email]
  }
}

# Carries the bucket policy and prefix object IDs so the publishing destinations wait for them (GuardDuty validates access on create).
resource "terraform_data" "destination_dependencies" {
  count = var.enable_publishing_destination ? 1 : 0

  input = var.destination_dependencies
}

# One publishing destination per Region, all exporting to the same bucket and KMS key; key = AWS Region.
resource "aws_guardduty_publishing_destination" "this" {
  for_each = var.enable_publishing_destination ? var.detectors : {}

  region           = each.key
  detector_id      = each.value.id
  destination_type = "S3"
  destination_arn  = var.destination_arn
  kms_key_arn      = var.destination_kms_key_arn

  tags = var.tags

  depends_on = [terraform_data.destination_dependencies]

  lifecycle {
    precondition {
      condition     = var.destination_arn != "" && var.destination_kms_key_arn != ""
      error_message = "destination_arn and destination_kms_key_arn must be set when enable_publishing_destination is true."
    }
  }
}
