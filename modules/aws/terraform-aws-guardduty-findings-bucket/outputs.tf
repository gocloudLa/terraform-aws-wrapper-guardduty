output "bucket_id" {
  description = "Findings bucket name."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Findings bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "destination_arn" {
  description = "GuardDuty publishing destination ARN (bucket ARN plus optional key prefix)."
  value       = local.destination_arn
}

output "destination_dependencies" {
  description = "Bucket policy and prefix object IDs; consumers reference them to wait until the destination is ready."
  value       = concat([aws_s3_bucket_policy.this.id], aws_s3_object.prefix[*].id)
}
