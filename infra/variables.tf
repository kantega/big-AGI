# variables.tf
variable "azure_subscription_id" {}
variable "openai_api_key" {}
variable "anthropic_api_key" {}
variable "gemini_api_key" {}

variable "allowed_ip" {
  description = "The IP address allowed to access the application"
  type        = string
  default     = "X.X.X.X/32"
}

variable "project_name" {
  description = "The main name for the project, used to derive other resource names"
  type        = string
  default     = "big-agi"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "Norway East"
}
