output "auto_enable_organization_members" {
  description = "Organization auto-enable setting for member accounts."
  value       = var.auto_enable_organization_members
}

output "feature_names" {
  description = "Organization protection plans managed by this module, keyed region-feature."
  value       = keys(aws_guardduty_organization_configuration_feature.this)
}

output "publishing_destination_arns" {
  description = "ARNs of the publishing destinations, keyed by Region."
  value       = { for region, destination in aws_guardduty_publishing_destination.this : region => destination.arn }
}
