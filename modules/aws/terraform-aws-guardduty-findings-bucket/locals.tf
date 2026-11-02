locals {
  prefix_with_slash = (
    length(trim(var.s3_key_prefix, "/")) > 0 ?
    "${trim(var.s3_key_prefix, "/")}/" :
    ""
  )

  # GuardDuty destination ARN: bucket ARN, optionally followed by the key prefix (no trailing slash).
  destination_arn = (
    length(local.prefix_with_slash) > 0 ?
    "${aws_s3_bucket.this.arn}/${trim(var.s3_key_prefix, "/")}" :
    aws_s3_bucket.this.arn
  )

  has_lifecycle = (
    var.lifecycle_glacier_transition_days != null ||
    var.lifecycle_expiration_days != null
  )
}
