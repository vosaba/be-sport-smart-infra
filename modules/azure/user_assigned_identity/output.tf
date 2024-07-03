output "identity_id" {
  description = "The ID of the user-assigned identity."
  value       = azurerm_user_assigned_identity.identity.id
}

output "identity_principal_id" {
  description = "The principal ID of the user-assigned identity."
  value       = azurerm_user_assigned_identity.identity.principal_id
}