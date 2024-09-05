terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  use_cli         = true
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = replace("${var.project_name}registry", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.project_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "3000"

    # Environment variables for the container
    OPENAI_API_KEY      = var.openai_api_key
    ANTHROPIC_API_KEY   = var.anthropic_api_key
    GEMINI_API_KEY      = var.gemini_api_key
  }

  site_config {
    always_on = true

    application_stack {
    docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
    docker_image_name        = "${var.project_name}:latest"
    docker_registry_username = azurerm_container_registry.acr.admin_username
    docker_registry_password = azurerm_container_registry.acr.admin_password
  }

    ip_restriction {
      ip_address = var.allowed_ip
      action     = "Allow"
      priority   = 100
      name       = "AllowSpecificIP"
    }

    ip_restriction {
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 200
      name       = "DenyAll"
    }
  }
  logs {
    detailed_error_messages = false
    failed_request_tracing = false
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb = 25
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [null_resource.docker_build]
}