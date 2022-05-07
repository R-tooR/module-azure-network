provider "azurerm" {
#  region = var.azure_region
  features {}
}

locals {
  vn_name      = "${var.env_name} ${var.vn_name}"
  cluster_name = "${var.cluster_name}-${var.env_name}"
}

resource "azurerm_resource_group" "flight-reservation" {
  name     = "flight-reservation"
  location = "eastus"
}

#data "azurerm_availability_zones" "available" {
#  state = "available"
#}

# <<<------------------------ Konfiguracja sieci ------------------------>>>
# DO POCZYTANIA I ZROZUMIENIA:
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network
# oraz resource'y:
# - subnet
# - route_table
# - nat_gateway
# - local_network_gateway
# - nat_gateway_public_ip_association
# https://docs.microsoft.com/en-us/azure/developer/terraform/hub-spoke-on-prem <- podobno sieci prywatne

resource "azurerm_virtual_network" "main" {
  address_space       = [var.main_vn_cidr]
  location            = "eastus"
  name                = "main"
  resource_group_name = azurerm_resource_group.flight-reservation.name

  tags = {
    "Name"                                        = local.vn_name,
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
  }
}

resource "azurerm_subnet" "public-subnet-a" {
  name                 = azurerm_virtual_network.main.id
  resource_group_name  = azurerm_resource_group.flight-reservation.name
  virtual_network_name = "public-subnet-a"
  address_prefixes     = [var.main_vn_cidr]

#  tags = {
#    "Name" = (
#      "${local.vn_name}-public-subnet-a"
#    ),
#    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
#    "kubernetes.io/role/elb"                      = "1"
#  }
}

resource "azurerm_subnet" "public-subnet-b" {
  name                 = azurerm_virtual_network.main.id
  resource_group_name  = azurerm_resource_group.flight-reservation.name
  virtual_network_name = "public-subnet-b"
  address_prefixes     = [var.main_vn_cidr]

#  tags = {
#    "Name" = (
#      "${local.vn_name}-public-subnet-b"
#    ),
#    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
#    "kubernetes.io/role/elb"                      = "1"
#  }
}

resource "azurerm_subnet" "private-subnet-a" {
  name                 = azurerm_virtual_network.main.id
  resource_group_name  = azurerm_resource_group.flight-reservation.name
  virtual_network_name = "private-subnet-a"
  address_prefixes     = [var.main_vn_cidr]

#  tags = {
#    "Name" = (
#      "${local.vn_name}-private-subnet-a"
#    ),
#    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
#    "kubernetes.io/role/elb"                      = "1"
#  }
}

resource "azurerm_subnet" "private-subnet-b" {
  name                 = azurerm_virtual_network.main.id
  resource_group_name  = azurerm_resource_group.flight-reservation.name
  virtual_network_name = "private-subnet-b"
  address_prefixes     = [var.main_vn_cidr]

#  tags = {
#    "Name" = (
#      "${local.vn_name}-private-subnet-b"
#    ),
#    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
#    "kubernetes.io/role/elb"                      = "1"
#  }
}

## -------------------------- Sieci publiczne ---------------------------

resource "azurerm_route_table" "public-route" {
  location            = "eastus"
  name                = azurerm_virtual_network.main.id
  resource_group_name = azurerm_resource_group.flight-reservation.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internet-traffic"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    "Name" = "${local.vn_name}-public-route"
  }
}

resource "azurerm_subnet_route_table_association" "public-a-association" {
  route_table_id = azurerm_route_table.public-route.id
  subnet_id      = azurerm_subnet.public-subnet-a.id
}

resource "azurerm_subnet_route_table_association" "public-b-association" {
  route_table_id = azurerm_route_table.public-route.id
  subnet_id      = azurerm_subnet.public-subnet-b.id
}

resource "azurerm_public_ip" "nat-a" {
  name                = "nat-a"
  location            = azurerm_resource_group.flight-reservation.location
  resource_group_name = azurerm_resource_group.flight-reservation.name
  allocation_method   = "Static"

  tags = {
    "Name" = "${local.vn_name}-NAT-a"
  }
}

resource "azurerm_public_ip" "nat-b" {
  name                = "nat-b"
  location            = azurerm_resource_group.flight-reservation.location
  resource_group_name = azurerm_resource_group.flight-reservation.name
  allocation_method   = "Static"

  tags = {
    "Name" = "${local.vn_name}-NAT-b"
  }
}

resource "azurerm_nat_gateway" "nat-gw-a" {
  name                = "public-a-nat-gateway"
  location            = azurerm_resource_group.flight-reservation.location
  resource_group_name = azurerm_resource_group.flight-reservation.name

  tags = {
    "Name" = "${local.vn_name}-NAT-gw-a"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat-gw-publ-a" {
  nat_gateway_id       = azurerm_nat_gateway.nat-gw-a.id
  public_ip_address_id = azurerm_public_ip.nat-a.id
}

resource "azurerm_nat_gateway" "nat-gw-b" {
  name                = "public-b-nat-gateway"
  location            = azurerm_resource_group.flight-reservation.location
  resource_group_name = azurerm_resource_group.flight-reservation.name

  tags = {
    "Name" = "${local.vn_name}-NAT-gw-b"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat-gw-publ-b" {
  nat_gateway_id       = azurerm_nat_gateway.nat-gw-b.id
  public_ip_address_id = azurerm_public_ip.nat-b.id
}

## ------------------------- Sieci prywatne ------------------------------

resource "azurerm_route_table" "private-route-a" {
  location            = "eastus"
  name                = azurerm_virtual_network.main.id
  resource_group_name = azurerm_resource_group.flight-reservation.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internet-traffic"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    "Name" = "${local.vn_name}-private-route-a"
  }
}

resource "azurerm_route_table" "private-route-b" {
  location            = "eastus"
  name                = azurerm_virtual_network.main.id
  resource_group_name = azurerm_resource_group.flight-reservation.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internet-traffic"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    "Name" = "${local.vn_name}-private-route-b"
  }
}

resource "azurerm_subnet_route_table_association" "private-a-association" {
  route_table_id = azurerm_route_table.private-route-a.id
  subnet_id      = azurerm_subnet.private-subnet-a.id
}

resource "azurerm_subnet_route_table_association" "private-b-association" {
  route_table_id = azurerm_route_table.private-route-b.id
  subnet_id      = azurerm_subnet.private-subnet-b.id
}
