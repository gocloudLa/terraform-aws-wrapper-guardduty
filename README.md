# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform GuardDuty Organization Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-guardduty/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-guardduty.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-guardduty.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-guardduty/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
Wrapper for organization-wide Amazon GuardDuty managed from the delegated administrator account:
auto-enables GuardDuty and its protection plans for every member account, and exports all organization
findings to a dedicated, KMS-encrypted S3 bucket in the log archive account.


### ✨ Features

- 🛡️ [Organization-wide auto-enable](#organization-wide-auto-enable) - GuardDuty enabled for every existing and new member account from the delegated administrator.

- 🌎 [Multi-Region](#multi-region) - One apply configures GuardDuty in every listed Region using the provider per-resource `region` argument.

- 🧩 [Protection plans](#protection-plans) - Opinionated protection plan defaults that can be overridden per feature.

- 📦 [Findings export to the log archive](#findings-export-to-the-log-archive) - Organization findings published to a KMS-encrypted S3 bucket in the log account.




## 🚀 Quick Start
```hcl
guardduty_parameters = {
  enable = true

  # -------------------------------------------------------------------------
  # Top-level — only add keys when you need non-defaults (see ../../locals.tf)
  # -------------------------------------------------------------------------
  # auto_enable_organization_members = "ALL" # ALL | NEW | NONE
  # tags                             = {}

  regions = ["us-east-2", "us-east-1"] # Default: [<aws.sec provider Region>]

  # -------------------------------------------------------------------------
  # features — entries replace the wrapper default for the same feature name.
  # -------------------------------------------------------------------------
  features = {
    # S3_DATA_EVENTS         = { auto_enable = "ALL" }
    # EKS_AUDIT_LOGS         = { auto_enable = "ALL" }
    # EBS_MALWARE_PROTECTION = { auto_enable = "ALL" }
    # RDS_LOGIN_EVENTS       = { auto_enable = "ALL" }
    # LAMBDA_NETWORK_LOGS    = { auto_enable = "ALL" }
    # RUNTIME_MONITORING = {
    #   auto_enable = "NONE"
    #   additional_configuration = {
    #     EKS_ADDON_MANAGEMENT         = "NONE"
    #     ECS_FARGATE_AGENT_MANAGEMENT = "NONE"
    #     EC2_AGENT_MANAGEMENT         = "NONE"
    #   }
    # }
  }

  # -------------------------------------------------------------------------
  # publishing_destination — export findings to S3 (log account) with KMS.
  # -------------------------------------------------------------------------
  publishing_destination = {
    # enable        = true
    # s3_key_prefix = "guardduty"
  }

  # -------------------------------------------------------------------------
  # log_bucket — commented lines show wrapper defaults; uncomment to override.
  # -------------------------------------------------------------------------
  log_bucket = {
    # bucket_name                       = null # default: "${common_name}-guardduty-findings-${log_account_id}"
    # enable_versioning                 = true
    # lifecycle_glacier_transition_days = null
    # lifecycle_expiration_days         = null

    force_destroy = true # Default: false
  }

  # -------------------------------------------------------------------------
  # kms — commented lines show wrapper defaults; uncomment to override.
  # -------------------------------------------------------------------------
  kms = {
    # alias_name              = null # default: "alias/${common_name}-guardduty"
    # description             = null
    # deletion_window_in_days = 30
    # enable_key_rotation     = true

    deletion_window_in_days = 7 # Default: 30
  }
}
```


## 🔧 Additional Features Usage

### Organization-wide auto-enable
Configures `aws_guardduty_organization_configuration` on `aws.sec` using the detector AWS created when the account was
designated as GuardDuty delegated administrator. `ALL` covers existing members, new accounts and the delegated administrator itself.


<details><summary>Enable GuardDuty for all organization accounts</summary>

```hcl
guardduty_parameters = {
  enable = true

  # auto_enable_organization_members = "ALL" # ALL | NEW | NONE
}
```


</details>


### Multi-Region
`regions` lists the Regions to protect; the `aws.sec` provider Region is the home Region and must be included.
For each Region the module reads the delegated administrator detector, configures `aws_guardduty_organization_configuration`
and its protection plans, and creates a publishing destination. All Regions export to the same bucket and KMS key in the
home Region (GuardDuty supports cross-Region export when bucket and key share a Region); bucket and key policies list
every Regional detector ARN.


<details><summary>Protect two Regions</summary>

```hcl
guardduty_parameters = {
  enable = true

  regions = ["us-east-2", "us-east-1"] # Default: [<aws.sec provider Region>]
}
```


</details>


### Protection plans
Each `features` entry becomes an `aws_guardduty_organization_configuration_feature`. Defaults enable S3, EKS audit logs,
EBS malware protection, RDS login events and Lambda network logs for `ALL` accounts; Runtime Monitoring stays `NONE` because it
deploys agents and adds cost. An entry replaces the default entry with the same name.


<details><summary>Turn on Runtime Monitoring with managed agents for EKS and ECS Fargate</summary>

```hcl
guardduty_parameters = {
  enable = true

  features = {
    RUNTIME_MONITORING = {
      auto_enable = "ALL" # Default: "NONE"
      additional_configuration = {
        EKS_ADDON_MANAGEMENT         = "ALL"  # Default: "NONE"
        ECS_FARGATE_AGENT_MANAGEMENT = "ALL"  # Default: "NONE"
        EC2_AGENT_MANAGEMENT         = "NONE"
      }
    }
  }
}
```


</details>


### Findings export to the log archive
Creates the CMK on `aws.kms`, the findings bucket on `aws.log` and an `aws_guardduty_publishing_destination` on `aws.sec`.
Bucket and key policies only allow `guardduty.amazonaws.com` scoped by `aws:SourceAccount` and the detectors `aws:SourceArn`,
and deny uploads without SSE-KMS or with a different key. The key prefix "folder" object is created because GuardDuty requires it to exist.
Set `publishing_destination.enable = false` to skip the bucket, key and destination.


<details><summary>Disable findings export</summary>

```hcl
guardduty_parameters = {
  enable = true

  publishing_destination = {
    enable = false # Default: true
  }
}
```


</details>




## 📑 Inputs
| Name                                         | Description                                                                                                                                      | Type           | Default                                                                | Required |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | ---------------------------------------------------------------------- | -------- |
| enable                                       | When `true`, configure GuardDuty organization settings (`count` gate).                                                                           | `bool`         | `false`                                                                | no       |
| regions                                      | Regions where the organization configuration, protection plans and findings export are managed; must include the `aws.sec` provider Region.      | `list(string)` | `[<aws.sec provider Region>]`                                          | no       |
| auto_enable_organization_members             | `auto_enable_organization_members` on `aws_guardduty_organization_configuration` (`ALL`, `NEW`, `NONE`).                                         | `string`       | `"ALL"`                                                                | no       |
| management_account.enable                    | Create the management account detector (`aws.org`) and add it as a GuardDuty member (`aws_guardduty_member`) in every Region in `regions`.       | `bool`         | `true`                                                                 | no       |
| features                                     | Map keyed by feature name with `auto_enable` and optional `additional_configuration` map; entries replace the wrapper default with the same key. | `map`          | `S3/EKS audit/EBS malware/RDS/Lambda = ALL, RUNTIME_MONITORING = NONE` | no       |
| publishing_destination.enable                | Create the KMS key, findings bucket and `aws_guardduty_publishing_destination`.                                                                  | `bool`         | `true`                                                                 | no       |
| publishing_destination.s3_key_prefix         | Key prefix for exported findings inside the bucket.                                                                                              | `string`       | `"guardduty"`                                                          | no       |
| kms.description                              | `description` on `aws_kms_key`.                                                                                                                  | `string`       | `` `KMS key for GuardDuty findings export ({common_name})` ``          | no       |
| kms.deletion_window_in_days                  | `deletion_window_in_days` on `aws_kms_key` (7–30).                                                                                               | `number`       | `30`                                                                   | no       |
| kms.enable_key_rotation                      | `enable_key_rotation` on `aws_kms_key`.                                                                                                          | `bool`         | `true`                                                                 | no       |
| kms.alias_name                               | `name` on `aws_kms_alias` (must start with `alias/`).                                                                                            | `string`       | `` `alias/{common_name}-guardduty` ``                                  | no       |
| log_bucket.bucket_name                       | Globally unique `bucket` name on `aws_s3_bucket`.                                                                                                | `string`       | `` `{common_name}-guardduty-findings-{log_account_id}` ``              | no       |
| log_bucket.force_destroy                     | `force_destroy` on `aws_s3_bucket`.                                                                                                              | `bool`         | `false`                                                                | no       |
| log_bucket.enable_versioning                 | S3 bucket versioning (`aws_s3_bucket_versioning`).                                                                                               | `bool`         | `true`                                                                 | no       |
| log_bucket.lifecycle_glacier_transition_days | Lifecycle rule: transition to `GLACIER` after N days; `null` skips.                                                                              | `number`       | `null`                                                                 | no       |
| log_bucket.lifecycle_expiration_days         | Lifecycle rule: expire objects after N days; `null` skips.                                                                                       | `number`       | `null`                                                                 | no       |
| tags                                         | A map of tags to assign to resources.                                                                                                            | `map`          | `{}`                                                                   | no       |







## ⚠️ Important Notes
- ⚠️ **Malware Protection for EC2 prerequisite:** `EBS_MALWARE_PROTECTION` fails with "you do not have the required AWS Organizations management account permission" unless the management account enabled trusted access for `malware-protection.guardduty.amazonaws.com` (add it to the organization `aws_service_access_principals`, or run `aws organizations enable-aws-service-access --service-principal malware-protection.guardduty.amazonaws.com`). Set `features = { EBS_MALWARE_PROTECTION = { auto_enable = "NONE" } }` to skip it.
- ⚠️ **Delegation prerequisite:** GuardDuty delegation is Regional. Register the delegated administrator first in **every** Region listed in `regions` with the service-delegation wrapper (`guardduty = "<sec account id>"` plus `guardduty_regions`) and apply the organization layer. Plans fail with "no GuardDuty detector found" for any Region without delegation.
- ℹ️ **Propagation:** `ALL` includes existing members and the delegated administrator; AWS may take up to 24 hours to apply the configuration to every account.
- ℹ️ **Malware Protection for S3:** Not covered by organization auto-enable; configure it per bucket.
- ⚠️ **Runtime Monitoring:** Use `RUNTIME_MONITORING` only; `EKS_RUNTIME_MONITORING` conflicts with it. Enabling it deploys agents and adds noticeable cost.
- ⚠️ **Destroy:** Removing the module does not disable GuardDuty in member accounts; it only drops the organization configuration and the findings export.



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 