module "kms" {
  source = "./modules/aws/terraform-aws-guardduty-kms"
  count  = local.publishing_destination_enable

  providers = { aws = aws.kms }

  description             = try(var.guardduty_parameters.kms.description, "KMS key for GuardDuty findings export (${local.common_name})")
  deletion_window_in_days = try(var.guardduty_parameters.kms.deletion_window_in_days, 30)
  enable_key_rotation     = try(var.guardduty_parameters.kms.enable_key_rotation, true)
  alias_name              = try(var.guardduty_parameters.kms.alias_name, "alias/${local.common_name}-guardduty")
  tags                    = merge(local.common_tags, try(var.guardduty_parameters.tags, var.guardduty_defaults.tags, null))

  sec_account_id = data.aws_caller_identity.sec.account_id
  detector_arns  = local.detector_arns
  log_account_id = data.aws_caller_identity.log.account_id
  log_region     = data.aws_region.log.region
}

module "findings_bucket" {
  source = "./modules/aws/terraform-aws-guardduty-findings-bucket"
  count  = local.publishing_destination_enable

  providers = { aws = aws.log }

  bucket_name       = try(var.guardduty_parameters.log_bucket.bucket_name, "${local.common_name}-guardduty-findings-${data.aws_caller_identity.log.account_id}")
  force_destroy     = try(var.guardduty_parameters.log_bucket.force_destroy, false)
  enable_versioning = try(var.guardduty_parameters.log_bucket.enable_versioning, true)
  tags              = merge(local.common_tags, try(var.guardduty_parameters.tags, var.guardduty_defaults.tags, null))

  s3_key_prefix  = local.s3_key_prefix
  kms_key_arn    = module.kms[0].key_arn
  sec_account_id = data.aws_caller_identity.sec.account_id
  detector_arns  = local.detector_arns

  lifecycle_glacier_transition_days = try(var.guardduty_parameters.log_bucket.lifecycle_glacier_transition_days, null)
  lifecycle_expiration_days         = try(var.guardduty_parameters.log_bucket.lifecycle_expiration_days, null)
}

module "organization" {
  source = "./modules/aws/terraform-aws-guardduty-organization"
  count  = local.guardduty_enable

  providers = {
    aws     = aws.sec
    aws.org = aws.org
  }

  home_region                      = local.home_region
  detectors                        = local.detectors
  delegated_admin_account_id       = data.aws_caller_identity.sec.account_id
  management_account_id            = data.aws_organizations_organization.this[0].master_account_id
  management_account_email         = data.aws_organizations_organization.this[0].master_account_email
  enable_management_account        = try(var.guardduty_parameters.management_account.enable, var.guardduty_defaults.management_account.enable, true)
  auto_enable_organization_members = try(var.guardduty_parameters.auto_enable_organization_members, "ALL")
  features                         = local.features
  tags                             = merge(local.common_tags, try(var.guardduty_parameters.tags, var.guardduty_defaults.tags, null))

  enable_publishing_destination = local.publishing_destination_enable == 1
  destination_arn               = try(module.findings_bucket[0].destination_arn, "")
  destination_kms_key_arn       = try(module.kms[0].key_arn, "")
  destination_dependencies      = try(module.findings_bucket[0].destination_dependencies, [])
}
