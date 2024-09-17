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

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
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
  sku_name            = "B3"
}

resource "azurerm_linux_web_app" "browserless" {
  name                = "${var.project_name}-browserless"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "3000"
    MAX_CONCURRENT_SESSIONS             = "10"
  }

  site_config {
    always_on = true
    application_stack {
      docker_registry_url = "https://registry.hub.docker.com"
      docker_image_name   = "browserless/chrome:latest"
    }

    ip_restriction {
      ip_address = var.allowed_ip
      action     = "Allow"
      priority   = 100
      name       = "AllowKantegaIP"
    }

    dynamic "ip_restriction" {
      for_each = toset(split(",", azurerm_linux_web_app.app.outbound_ip_addresses))
      content {
        ip_address = "${ip_restriction.value}/32"
        action     = "Allow"
        priority   = 200
        name       = "A-${ip_restriction.value}"
      }
    }

    ip_restriction {
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 300
      name       = "DenyAll"
    }
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 25
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_service_plan.asp,
    azurerm_subnet.subnet
  ]
}

resource "azurerm_linux_web_app" "app" {
  name                = var.project_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE        = "false"
    WEBSITES_PORT                              = "3000"
    OPENAI_API_KEY                             = var.openai_api_key
    ANTHROPIC_API_KEY                          = var.anthropic_api_key
    GEMINI_API_KEY                             = var.gemini_api_key
    DOCKER_ENABLE_CI                           = "true"
    MICROSOFT_PROVIDER_AUTHENTICATION_SECRET   = var.azure_ad_client_secret
    WEBSITE_AUTH_AAD_ALLOWED_TENANTS           = var.azure_ad_tenant_id
    PUPPETEER_WSS_ENDPOINT                     = "wss://${var.project_name}-browserless.azurewebsites.net"
  }

  auth_settings_v2 {
    auth_enabled             = true
    default_provider         = "azureactivedirectory"
    require_authentication   = true
    unauthenticated_action   = "RedirectToLoginPage"
    http_route_api_prefix    = "/.auth"
    forward_proxy_convention = "NoProxy"
    excluded_paths           = []
    require_https            = true
    runtime_version          = "~1"

    active_directory_v2 {
      client_id                       = var.azure_ad_client_id
      client_secret_setting_name      = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
      tenant_auth_endpoint            = "https://sts.windows.net/${var.azure_ad_tenant_id}/v2.0"
      allowed_applications            = [var.azure_ad_client_id]
      allowed_audiences               = ["api://${var.azure_ad_client_id}"]
      allowed_groups                  = []
      allowed_identities              = []
      jwt_allowed_client_applications = []
      jwt_allowed_groups              = []
      login_parameters                = {}
      www_authentication_disabled     = false
    }

    login {
      token_store_enabled               = true
      token_refresh_extension_time      = 72
      preserve_url_fragments_for_logins = false
      cookie_expiration_convention      = "FixedTime"
      cookie_expiration_time            = "08:00:00"
      nonce_expiration_time             = "00:05:00"
      validate_nonce                    = true
      allowed_external_redirect_urls    = []
    }
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
      name       = "KantegaIP"
    }

    ip_restriction {
      ip_address = "0.0.0.0/0"
      action     = "Deny"
      priority   = 300
      name       = "DenyAll"
    }
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 25
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  sticky_settings {
    app_setting_names = ["MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"]
}

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_subnet.subnet
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "app_vnet_integration" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = azurerm_subnet.subnet.id
}

resource "azurerm_app_service_virtual_network_swift_connection" "browserless_vnet_integration" {
  app_service_id = azurerm_linux_web_app.browserless.id
  subnet_id      = azurerm_subnet.subnet.id
  }
