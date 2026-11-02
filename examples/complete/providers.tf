provider "aws" {
  region = local.metadata.aws_region
}

provider "aws" {
  alias  = "org"
  region = local.metadata.aws_region
}

provider "aws" {
  alias  = "sec"
  region = local.metadata.aws_region
}

provider "aws" {
  alias  = "log"
  region = local.metadata.aws_region
}

provider "aws" {
  alias  = "kms"
  region = local.metadata.aws_region
}

# Local multi-account testing: create a git-ignored providers_override.tf adding `profile` to each alias.
