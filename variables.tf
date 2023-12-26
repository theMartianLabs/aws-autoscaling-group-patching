// variable "eu-region" {
//   type    = string
//   default = ""
// }


variable "lambda_function_name" {
  type    = string
  default = "lambda_asg_patching"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime for lambda"
}

variable "timeout" {
  type    = number
  default = 900
}

variable "lambda_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the lambda"
}


variable "vpc_id" {
  type = string
}

variable "lambda_asg_env_variables" {
  default = {}
}


variable "cron_schedules" {
  default = {}
}

// variable "vpc_id" {
//   type    = string
//   default = ""
// }

// variable "vpc_id" {
//   type    = string
//   default = ""
// }

// variable "vpc_id" {
//   type    = string
//   default = ""
// }

// variable "vpc_id" {
//   type    = string
//   default = ""
// }