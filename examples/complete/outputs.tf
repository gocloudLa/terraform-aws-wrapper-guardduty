output "enabled" {
  description = "Whether the wrapper created GuardDuty organization resources."
  value       = module.wrapper_guardduty.enabled
}

output "detector_ids" {
  value = module.wrapper_guardduty.detector_ids
}

output "organization_auto_enable" {
  value = module.wrapper_guardduty.organization_auto_enable
}

output "publishing_destination_arns" {
  value = module.wrapper_guardduty.publishing_destination_arns
}

output "s3_bucket_id" {
  value = module.wrapper_guardduty.s3_bucket_id
}

output "kms_key_arn" {
  value = module.wrapper_guardduty.kms_key_arn
}
