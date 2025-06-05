output "resource_group_name1" {
    description = "this declare name of rg"
    value = azurerm_resource_group.task_rg.name
}

output "azurerm_storage_account" {
    description = "account tier"
    value = azurerm_storage_account.task_storage.account_tier
}

output "storage_account_replication_type" {
    description = "account replication type"
    value = azurerm_storage_account.task_storage.account_replication_type
}



