output "app_service_source_control_id" {
  value = azurerm_app_service_source_control.app_source_control.id
}

output "federated_identity_credential_id" {
  value = azurerm_federated_identity_credential.app_federated_identity[*].id
}