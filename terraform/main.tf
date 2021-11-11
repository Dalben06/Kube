terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "2.25"
    }
  }
}

provider "azurerm" {
    features {
    }
}

resource "azurerm_resource_group" "kube-resource" {
  name     = "kube-resource"
  location = "eastus"
}

resource "azurerm_container_registry" "dalbenkubeacr" {
  name                = "dalbenkubeacr"
  resource_group_name = azurerm_resource_group.kube-resource.name
  location            = azurerm_resource_group.kube-resource.location
  sku                 = "Basic"
  admin_enabled       = false
 
}


resource "azurerm_kubernetes_cluster" "aks-infra" {
  name                = "aks-infra"
  location            = azurerm_resource_group.kube-resource.location
  resource_group_name = azurerm_resource_group.kube-resource.name
  dns_prefix          = "aks-infra"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
  }

  service_principal {
    client_id = var.client
    client_secret = var.secret
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  tags = {
    Environment = "Production"
  }
}

data "azuread_service_principal" "aks-principal" {
    application_id = var.client
}

resource "azurerm_role_assignment" "acr-pull" {
  scope = azurerm_container_registry.dalbenkubeacr.id
  role_definition_name = "AcrPull"
  principal_id = data.azuread_service_principal.aks-principal.id
  skip_service_principal_aad_check = true
}


variable "client" {
  
}
variable "secret" {
  
}
