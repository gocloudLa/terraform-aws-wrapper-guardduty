variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for GuardDuty findings."
}

variable "force_destroy" {
  type        = bool
  description = "Allow bucket destruction when non-empty."
  default     = false
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 versioning on the findings bucket."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bucket."
  default     = {}
}

variable "s3_key_prefix" {
  type        = string
  description = "Key prefix for exported findings; empty string writes at the bucket root."
  default     = ""
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for default bucket encryption (same key used by the publishing destination)."
}

variable "sec_account_id" {
  type        = string
  description = "GuardDuty delegated administrator account ID (aws:SourceAccount in the bucket policy)."
}

variable "detector_arns" {
  type        = list(string)
  description = "ARNs of the delegated administrator GuardDuty detectors, one per Region (aws:SourceArn in the bucket policy)."
}

variable "lifecycle_glacier_transition_days" {
  type        = number
  description = "Transition current objects to GLACIER after N days; null skips."
  default     = null
}

variable "lifecycle_expiration_days" {
  type        = number
  description = "Expire current objects after N days; null skips."
  default     = null
}
