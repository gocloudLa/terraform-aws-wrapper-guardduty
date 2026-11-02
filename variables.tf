/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

/*----------------------------------------------------------------------*/
/* GuardDuty | Variable Definition                                      */
/*----------------------------------------------------------------------*/

variable "guardduty_parameters" {
  type        = any
  description = "Organization GuardDuty auto-enable, protection plans, and findings export configuration."
  default     = {}
}

variable "guardduty_defaults" {
  type        = any
  description = "Default values merged into each entry of guardduty_parameters."
  default     = {}
}
