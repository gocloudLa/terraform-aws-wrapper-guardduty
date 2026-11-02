data "aws_caller_identity" "sec" {
  provider = aws.sec
}

data "aws_region" "sec" {
  provider = aws.sec
}

data "aws_caller_identity" "log" {
  provider = aws.log
}

data "aws_region" "log" {
  provider = aws.log
}

data "aws_organizations_organization" "this" {
  count    = local.guardduty_enable
  provider = aws.org
}

# Detector is created by AWS when the account is designated as GuardDuty delegated administrator (service-delegation wrapper).
# Key: AWS Region (guardduty_parameters.regions).
data "aws_guardduty_detector" "sec" {
  for_each = local.regions
  provider = aws.sec

  region = each.value
}
