variable "azure_subscription_id" {}
variable "openai_api_key" {}
variable "anthropic_api_key" {}
variable "gemini_api_key" {}

variable "allowed_ip" {
  type    = string
  default = "X.X.X.X/32"
}

variable "project_name" {
  type    = string
  default = "big-agi"
}

variable "location" {
  type    = string
  default = "Norway East"
}
