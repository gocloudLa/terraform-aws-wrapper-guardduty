module "wrapper_guardduty" {
  source = "../../"

  providers = {
    aws.org = aws.org # Organization Management Account
    aws.sec = aws.sec # Security Tooling Account ( GuardDuty delegated administrator )
    aws.log = aws.log # Security Logging Account ( if exists )
    aws.kms = aws.kms # Security KMS Account ( if exists )
  }

  metadata = local.metadata

  guardduty_parameters = {
    enable = true

    # -------------------------------------------------------------------------
    # Top-level — only add keys when you need non-defaults (see ../../locals.tf)
    # -------------------------------------------------------------------------
    # auto_enable_organization_members = "ALL" # ALL | NEW | NONE
    # tags                             = {}

    # regions = ["us-east-2", "us-east-1"] # Default: [<aws.sec provider Region>]

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

  guardduty_defaults = {}
}
