/* variable "location" {
    type = string
    description = "location"
} */

variable "admin_password" {
    type = string
    description = "adminp"
}

variable "kv_secret_value" {
    type = string
    sensitive = true
    description = "secret value for keyvault"
}

variable "subscription_id" {
    type = string
    description = "using for subscription id"
}

variable "tenant_id" {
    type = string
    description = "using for azure tenant id"  
}

variable "client_id" {
    type = string
    description = "using for azue terraform app client id"  
}

variable "client_secret" {
    type = string
    description = "using for azue terraform app client secret"
}

variable "resource_group_name" {
    type = string
    description = "defining resource group name for this project"
}

variable "object_id" {
    type = string
    description = "defining object id for this project"
}

