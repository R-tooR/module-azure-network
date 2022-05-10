output "vn_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  value = [
    azurerm_subnet.public-subnet-a.id,
#    azurerm_subnet.public-subnet-b.name,
#    azurerm_subnet.private-subnet-a.name,
#    azurerm_subnet.private-subnet-b.name,
  ]
}

output "public_subnet_ids" {
  value = [
    azurerm_subnet.public-subnet-a.id,
#    azurerm_subnet.public-subnet-b.name,
  ]
}

output "private_subnet_ids" {
  value = [
    azurerm_subnet.private-subnet-a.id,
#    azurerm_subnet.private-subnet-b.name,
  ]
}
