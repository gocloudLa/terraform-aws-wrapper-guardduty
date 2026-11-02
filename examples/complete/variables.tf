/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

# variable "metadata" {
#   type = any
# }

/*----------------------------------------------------------------------*/
/* GuardDuty | Variable Definition                                      */
/*----------------------------------------------------------------------*/
variable "guardduty_parameters" {
  type        = any
  description = "GuardDuty parameteres to configure the wrapper module"
  default     = {}
}

variable "guardduty_defaults" {
  type        = any
  description = "GuardDuty default parameteres for the wrapper module"
  default     = {}
}
