provider "azurerm" {
  features {}
  subscription_id = "4aa1083f-7491-42aa-b0e6-32d54bc43d80"
}

resource "azurerm_resource_group" "rg" {
  name     = "sock-shop-rg"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "sock-shop-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "private-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet_2" {
  name                 = "private-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "public_subnet_1" {
  name                 = "public-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.101.0/24"]
}

resource "azurerm_subnet" "public_subnet_2" {
  name                 = "public-subnet-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.102.0/24"]
}

resource "azurerm_nat_gateway" "nat" {
  name                = "sock-shop-nat"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip" {
  nat_gateway_id = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_public_ip.id
}

resource "azurerm_public_ip" "nat_public_ip" {
  name                = "sock-shop-nat-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "sock-shop-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "sockshop"

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D2_v2"
    node_count = 1
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
    auto_scaling_enabled = true
    min_count = 1               
    max_count = 3
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = "10.0.3.0/24"
    dns_service_ip    = "10.0.3.10"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "node_pool_1" {
  name                = "nodepool1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size             = "Standard_D2_v2"
  node_count          = 1
}

resource "azurerm_kubernetes_cluster_node_pool" "node_pool_2" {
  name                = "nodepool2"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size             = "Standard_D2_v2"
  node_count          = 1
}
