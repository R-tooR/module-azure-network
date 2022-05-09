provider "azurerm" {
  #  region = var.azure_region
  features {}
}

locals {
  vn_name      = "${var.env_name} ${var.vn_name}"
  cluster_name = "${var.cluster_name}-${var.env_name}"
}

resource "azurerm_resource_group" "flight-reservation-app" {
  name     = "flight-reservation-app"
  location = var.azure_region
}


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
# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps

resource "azurerm_virtual_network" "main" {
  address_space       = [var.main_vn_cidr]
  location            = var.azure_region
  name                = "main"
  resource_group_name = azurerm_resource_group.flight-reservation-app.name

  tags = {
    "Name"                                        = local.vn_name,
#    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
  }
}

resource "azurerm_subnet" "public-subnet-a" {
  name                 = "public-subnet-a"
  resource_group_name  = azurerm_resource_group.flight-reservation-app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_a_cidr]

}

#resource "azurerm_subnet" "public-subnet-b" {
#  name                 = azurerm_virtual_network.main.id
#  resource_group_name  = azurerm_resource_group.flight-reservation-app.name
#  virtual_network_name = "public-subnet-b"
#  address_prefixes     = [var.public_subnet_b_cidr]
#
#}
#
#resource "azurerm_subnet" "private-subnet-a" {
#  name                 = azurerm_virtual_network.main.id
#  resource_group_name  = azurerm_resource_group.flight-reservation-app.name
#  virtual_network_name = "private-subnet-a"
#  address_prefixes     = [var.private_subnet_a_cidr]
#
#}
#
#resource "azurerm_subnet" "private-subnet-b" {
#  name                 = azurerm_virtual_network.main.id
#  resource_group_name  = azurerm_resource_group.flight-reservation-app.name
#  virtual_network_name = "private-subnet-b"
#  address_prefixes     = [var.private_subnet_b_cidr]
#
#}

## -------------------------- Sieci publiczne ---------------------------

resource "azurerm_route_table" "public-route" {
  location            = var.azure_region
  name                = azurerm_virtual_network.main.name
  resource_group_name = azurerm_resource_group.flight-reservation-app.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internet-traffic"
    next_hop_type  = "VirtualNetworkGateway"
  }

  tags = {
    "Name" = "${local.vn_name}-public-route"
  }
}

resource "azurerm_subnet_route_table_association" "public-a-association" {
  route_table_id = azurerm_route_table.public-route.id
  subnet_id      = azurerm_subnet.public-subnet-a.id
}

#resource "azurerm_subnet_route_table_association" "public-b-association" {
#  route_table_id = azurerm_route_table.public-route.id
#  subnet_id      = azurerm_subnet.public-subnet-b.id
#}
#
resource "azurerm_public_ip" "nat-a" {
  name                = "nat-a"
  location            = azurerm_resource_group.flight-reservation-app.location
  resource_group_name = azurerm_resource_group.flight-reservation-app.name
  allocation_method   = "Static"
  sku = "Standard"
#  sku_tier = "Global"

  tags = {
    "Name" = "${local.vn_name}-NAT-a"
  }
}

#resource "azurerm_public_ip" "nat-b" {
#  name                = "nat-b"
#  location            = azurerm_resource_group.flight-reservation-app.location
#  resource_group_name = azurerm_resource_group.flight-reservation-app.name
#  allocation_method   = "Static"
#  sku = "Standard"
#  sku_tier = "Global"
#
#  tags = {
#    "Name" = "${local.vn_name}-NAT-b"
#  }
#}
#
resource "azurerm_nat_gateway" "nat-gw-a" {
  name                = "public-a-nat-gateway"
  location            = azurerm_resource_group.flight-reservation-app.location
  resource_group_name = azurerm_resource_group.flight-reservation-app.name
  tags = {
    "Name" = "${local.vn_name}-NAT-gw-a"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat-gw-publ-a" {
  nat_gateway_id       = azurerm_nat_gateway.nat-gw-a.id
  public_ip_address_id = azurerm_public_ip.nat-a.id
}
#
#resource "azurerm_nat_gateway" "nat-gw-b" {
#  name                = "public-b-nat-gateway"
#  location            = azurerm_resource_group.flight-reservation-app.location
#  resource_group_name = azurerm_resource_group.flight-reservation-app.name
#
#  tags = {
#    "Name" = "${local.vn_name}-NAT-gw-b"
#  }
#}
#
#resource "azurerm_nat_gateway_public_ip_association" "nat-gw-publ-b" {
#  nat_gateway_id       = azurerm_nat_gateway.nat-gw-b.id
#  public_ip_address_id = azurerm_public_ip.nat-b.id
#}

## ------------------------- Sieci prywatne ------------------------------

#resource "azurerm_route_table" "private-route-a" {
#  location            = var.azure_region
#  name                = azurerm_virtual_network.main.id
#  resource_group_name = azurerm_resource_group.flight-reservation-app.name
#
#  route {
#    address_prefix = "0.0.0.0/0"
#    name           = "internet-traffic-a"
#    next_hop_type  = "VirtualNetworkGateway"
#  }
#
#  tags = {
#    "Name" = "${local.vn_name}-private-route-a"
#  }
#}

#resource "azurerm_route_table" "private-route-b" {
#  location            = var.azure_region
#  name                = azurerm_virtual_network.main.id
#  resource_group_name = azurerm_resource_group.flight-reservation-app.name
#
#  route {
#    address_prefix = "0.0.0.0/0"
#    name           = "internet-traffic-b"
#    next_hop_type  = "VirtualNetworkGateway"
#  }
#
#  tags = {
#    "Name" = "${local.vn_name}-private-route-b"
#  }
#}

#resource "azurerm_subnet_route_table_association" "private-a-association" {
#  route_table_id = azurerm_route_table.private-route-a.id
#  subnet_id      = azurerm_subnet.private-subnet-a.id
#}
#
#resource "azurerm_subnet_route_table_association" "private-b-association" {
#  route_table_id = azurerm_route_table.private-route-b.id
#  subnet_id      = azurerm_subnet.private-subnet-b.id
#}
