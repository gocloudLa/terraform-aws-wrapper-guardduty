locals {
  guardduty_enable = try(var.guardduty_parameters.enable, false) ? 1 : 0

  publishing_destination_enable = local.guardduty_enable == 1 && try(var.guardduty_parameters.publishing_destination.enable, true) ? 1 : 0

  s3_key_prefix = try(var.guardduty_parameters.publishing_destination.s3_key_prefix, "guardduty")

  # Organization protection plans. User entries replace the default entry with the same feature name.
  default_features = {
    S3_DATA_EVENTS         = { auto_enable = "ALL" }
    EKS_AUDIT_LOGS         = { auto_enable = "ALL" }
    EBS_MALWARE_PROTECTION = { auto_enable = "ALL" }
    RDS_LOGIN_EVENTS       = { auto_enable = "ALL" }
    LAMBDA_NETWORK_LOGS    = { auto_enable = "ALL" }
    RUNTIME_MONITORING = {
      auto_enable = "NONE"
      additional_configuration = {
        EKS_ADDON_MANAGEMENT         = "NONE"
        ECS_FARGATE_AGENT_MANAGEMENT = "NONE"
        EC2_AGENT_MANAGEMENT         = "NONE"
      }
    }
  }

  features = merge(local.default_features, try(var.guardduty_parameters.features, {}))

  # Home Region = aws.sec provider Region; every listed Region needs the GuardDuty delegation (service-delegation guardduty_regions).
  home_region = data.aws_region.sec.region
  regions     = local.guardduty_enable == 1 ? toset(try(var.guardduty_parameters.regions, [local.home_region])) : toset([])

  # Delegated administrator detector per Region (auto-created by the delegation). Key: AWS Region.
  detectors = {
    for region, detector in data.aws_guardduty_detector.sec :
    region => {
      id  = detector.id
      arn = detector.arn
    }
  }
  # output "debug_detectors" { value = local.detectors }

  detector_arns = [for region in sort(keys(local.detectors)) : local.detectors[region].arn]
}
