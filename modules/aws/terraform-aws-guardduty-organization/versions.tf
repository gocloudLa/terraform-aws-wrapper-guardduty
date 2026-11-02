terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.70"
      configuration_aliases = [aws.org]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
