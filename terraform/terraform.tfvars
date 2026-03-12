# Terraform variables values
# Customize these values for your environment

resource_group_name  = "rg-terraform-cloud"
location             = "France Central"  # Région France
environment          = "dev"
prefix               = "tfcloud"
storage_account_name = "tfcloudstorage2026"
admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
vm_size              = "Standard_B2s_v2"
db_admin_username    = "dbadmin"
db_admin_password    = "YourSecurePassword123!"
db_name              = "appdb"
