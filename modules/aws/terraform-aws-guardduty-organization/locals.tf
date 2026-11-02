locals {
  # additional_configuration is an ordered list in the provider: emit it in the order the GuardDuty API returns it,
  # otherwise every plan shows a replacement. Names not listed here go last, sorted.
  additional_configuration_order = [
    "ECS_FARGATE_AGENT_MANAGEMENT",
    "EC2_AGENT_MANAGEMENT",
    "EKS_ADDON_MANAGEMENT",
  ]

  # Organization protection plans per Region.
  # Key: "<region>-<feature>" (e.g. "us-east-1-S3_DATA_EVENTS").
  features_tmp = [
    for region, detector in var.detectors :
    [
      for feature, cfg in var.features :
      {
        "${region}-${feature}" = {
          region      = region
          detector_id = detector.id
          name        = feature
          auto_enable = cfg.auto_enable
          additional_configuration = [
            for name in concat(
              [for n in local.additional_configuration_order : n if contains(keys(cfg.additional_configuration), n)],
              sort([for n in keys(cfg.additional_configuration) : n if !contains(local.additional_configuration_order, n)]),
            ) :
            {
              name        = name
              auto_enable = cfg.additional_configuration[name]
            }
          ]
        }
      }
    ]
  ]

  features = merge(flatten(local.features_tmp)...)
  # output "debug_features" { value = local.features }
}
