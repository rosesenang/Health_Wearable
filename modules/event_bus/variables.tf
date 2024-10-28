# modules/event_bus/variables.tf

variable "project_name" {
  type        = string
  description = "Project name for tagging resources"
  default     = "health-wearable-project"
}

variable "heart_rate_threshold" {
  type        = number
  description = "Threshold for abnormal heart rate detection"
  default     = 100
}

# modules/event_bus/variables.tf

variable "lambda_zip_file" {
  type        = string
  description = "Path to the zipped Lambda function code"
  default     = "./function.zip" 
}

variable "caregiver_email" {
  type        = string
  description = "Email address for caregiver notifications"
}

data "aws_caller_identity" "current" {}
