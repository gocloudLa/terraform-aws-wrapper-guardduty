variable "description" {
  type        = string
  description = "KMS key description."
}

variable "deletion_window_in_days" {
  type        = number
  description = "Waiting period after scheduled deletion (7-30)."
  default     = 30
}

variable "enable_key_rotation" {
  type        = bool
  description = "Enable automatic annual key rotation."
  default     = true
}

variable "alias_name" {
  type        = string
  description = "KMS alias name (must start with alias/)."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the KMS key."
  default     = {}
}

variable "sec_account_id" {
  type        = string
  description = "GuardDuty delegated administrator account ID (aws:SourceAccount in the key policy)."
}

variable "detector_arns" {
  type        = list(string)
  description = "ARNs of the delegated administrator GuardDuty detectors, one per Region (aws:SourceArn in the key policy)."
}

variable "log_account_id" {
  type        = string
  description = "Account ID that owns the findings S3 bucket (log provider)."
}

variable "log_region" {
  type        = string
  description = "Region of the findings S3 bucket (for kms:ViaService)."
}
