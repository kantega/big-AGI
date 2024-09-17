variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID - Found in the Azure portal under 'Subscriptions'."
}

variable "azure_ad_tenant_id" {
  type        = string
  description = "Azure AD Tenant ID - Found in the Azure portal under 'Azure Entra ID' > 'Overview'."
}

variable "azure_ad_client_id" {
  type        = string
  description = "Azure AD Client ID - Found in the Azure portal under 'Azure Entra ID' > 'App registrations' > 'Your Application' > 'Overview'."
}

variable "azure_ad_client_secret" {
  type        = string
  description = "Azure AD Client Secret - Generated in the Azure portal under 'Azure Entra ID' > 'App registrations' > 'Your Application' > 'Certificates & secrets'."
}

variable "openai_api_key" {
  type        = string
  description = "OpenAI API Key - Retrieved from the OpenAI API Platform."
}

variable "anthropic_api_key" {
  type        = string
  description = "Anthropic API Key - Retrieved from the Anthropic API console."
}

variable "gemini_api_key" {
  type        = string
  description = "Gemini API Key - Retrieved from the Google Cloud AI dashboard."
}

variable "allowed_ip" {
  type        = string
  default     = "X.X.X.X/32"
  description = "IP address allowed to access resources. Use CIDR notation."
}

variable "project_name" {
  type        = string
  default     = "big-agi"
  description = "Name of the project that determines resource names in Azure."
}

variable "location" {
  type        = string
  default     = "Norway East"
  description = "Azure region where resources will be deployed."
}
