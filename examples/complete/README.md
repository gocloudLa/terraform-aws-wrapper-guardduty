# Complete example 🚀

Runnable root module wiring for terraform-aws-wrapper-guardduty; parameters follow the same variable pattern as other GoCloud wrappers (metadata, guardduty_parameters, guardduty_defaults).

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
Demonstrate organization-wide GuardDuty from the delegated administrator account with findings exported to a KMS-encrypted S3 bucket; production should tighten log_bucket/kms settings via tfvars or a higher-level stack.

#### Key Features Demonstrated
- **metadata** — Defined in `metadata.tf` (same pattern as other examples; optional `variable "metadata"` remains commented in `variables.tf`).
- **guardduty_parameters** — `enable = true` plus nested `features`, `publishing_destination`, `log_bucket` and `kms` overrides.
- **guardduty_defaults** — Same pattern as other wrappers (`tags` fallback alongside `guardduty_parameters.tags` and `metadata.common_tags`).
- **Non-defaults in the example** — Literals with `# Default: …` comments vs wrapper `../../locals.tf`.
- **Providers** — `aws.org`, `aws.sec`, `aws.log` and `aws.kms` aliases default to the same credentials; add a git-ignored `providers_override.tf` with per-alias `profile` for multi-account tests.

## 🚀 Quick Start

```bash
terraform init
terraform plan
terraform apply
```

## 🔒 Security Notes

⚠️ **Production Considerations**: 
- This example may include configurations that are not suitable for production environments
- Review and customize security settings, access controls, and resource configurations
- Ensure compliance with your organization's security policies
- Consider implementing proper monitoring, logging, and backup strategies

## 📖 Documentation

For detailed module documentation and additional examples, see the main [README.md](../../README.md) file. 