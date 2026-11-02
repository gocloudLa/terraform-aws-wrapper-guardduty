output "enabled" {
  description = "Whether GuardDuty organization resources were created (guardduty_parameters.enable)."
  value       = local.guardduty_enable == 1
}

output "detector_ids" {
  description = "GuardDuty detector IDs in the delegated administrator account, keyed by Region."
  value       = { for region, detector in local.detectors : region => detector.id }
}

output "organization_auto_enable" {
  description = "Organization auto-enable setting for member accounts (ALL, NEW, or NONE)."
  value       = try(module.organization[0].auto_enable_organization_members, null)
}

output "publishing_destination_arns" {
  description = "ARNs of the GuardDuty findings publishing destinations, keyed by Region."
  value       = try(module.organization[0].publishing_destination_arns, {})
}

output "s3_bucket_id" {
  description = "Findings export S3 bucket name (log account)."
  value       = try(module.findings_bucket[0].bucket_id, null)
}

output "kms_key_arn" {
  description = "KMS key ARN used for GuardDuty findings export encryption."
  value       = try(module.kms[0].key_arn, null)
}
