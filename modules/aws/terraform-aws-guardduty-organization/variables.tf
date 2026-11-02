variable "home_region" {
  type        = string
  description = "Home Region (provider Region); must be one of the detectors keys."
}

variable "detectors" {
  type = map(object({
    id  = string
    arn = string
  }))
  description = "Delegated administrator GuardDuty detectors keyed by Region."
}

variable "delegated_admin_account_id" {
  type        = string
  description = "Account ID of the provider (GuardDuty delegated administrator)."
}

variable "management_account_id" {
  type        = string
  description = "AWS Organizations management account ID (must differ from the delegated administrator)."
}

variable "management_account_email" {
  type        = string
  description = "AWS Organizations management account email (required by aws_guardduty_member)."
  default     = ""
}

variable "enable_management_account" {
  type        = bool
  description = "Add the management account as a GuardDuty member in every Region (auto-enable does not cover it)."
  default     = true
}

variable "auto_enable_organization_members" {
  type        = string
  description = "Auto-enable GuardDuty for organization members: ALL, NEW, or NONE."
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "NEW", "NONE"], var.auto_enable_organization_members)
    error_message = "auto_enable_organization_members must be one of ALL, NEW, NONE."
  }
}

variable "features" {
  type = map(object({
    auto_enable              = string
    additional_configuration = optional(map(string), {})
  }))
  description = "Organization protection plans keyed by feature name, with auto_enable and optional additional_configuration."
  default     = {}
}

variable "enable_publishing_destination" {
  type        = bool
  description = "Create an S3 publishing destination for findings."
  default     = false
}

variable "destination_arn" {
  type        = string
  description = "S3 destination ARN (bucket ARN plus optional prefix)."
  default     = ""
}

variable "destination_kms_key_arn" {
  type        = string
  description = "KMS key ARN GuardDuty uses to encrypt exported findings."
  default     = ""
}

variable "destination_dependencies" {
  type        = list(string)
  description = "IDs the publishing destinations must wait for (bucket policy, prefix object)."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to taggable resources."
  default     = {}
}
