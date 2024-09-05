resource "null_resource" "docker_build" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
      cd "${path.module}/.."

      az acr login --name ${azurerm_container_registry.acr.name}

      if ! docker version > /dev/null 2>&1; then
        echo "Docker is not running. Please start Docker and try again."
        exit 1
      fi

      # Create a temporary Buildx builder with docker-container driver
      BUILDER_NAME=temp-builder-$(date +%s)
      docker buildx create --name $BUILDER_NAME --use --driver docker-container

      docker image remove ${azurerm_container_registry.acr.login_server}/${var.project_name}:latest || true
      az acr repository delete --name ${azurerm_container_registry.acr.name} --image ${var.project_name}:latest --yes || true

      docker buildx build --platform linux/amd64,linux/arm64 -t ${azurerm_container_registry.acr.login_server}/${var.project_name}:latest --push .

      # Clean up the temporary builder
      docker buildx rm $BUILDER_NAME
    EOT
  }

  depends_on = [azurerm_container_registry.acr]
}
