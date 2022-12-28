# resource "tfe_organization" "tfe_org_name" {
#   name  = "vault-org"
#   email = "your@email.com"
#   provider = tfe
# }

# resource "tfe_workspace" "vault_infra" {
#   name         = "vault-infra"
#   organization = tfe_organization.tfe_org_name.name
# }

# resource "tfe_workspace" "vault_playpen" {
#   name         = "vault-playpen"
#   organization = tfe_organization.tfe_org_name.name
# }

# resource "tfe_variable_set" "tf_vault_creds" {
#   name          = "TF_Vault_Creds"
#   description   = "AppRole credentials that allow Terraform access to Vault for provisioning"
#   organization  = tfe_organization.tfe_org_name.name
# }

# # resource "tfe_workspace_variable_set" "tf_vault_creds" {
# #   workspace_id    = tfe_workspace.tfe_org_name.id
# #   variable_set_id = tfe_variable_set.tf_vault_creds.id
# # }

# resource "tfe_variable" "role-id" {
#   key             = "role-id"
#   value           = "my_value_name"
#   category        = "terraform" #rather than env
#   description     = "Approle role-id for TF to use to connect to Vault"
#   variable_set_id = tfe_variable_set.tf_vault_creds.id
# }

# resource "tfe_variable" "secret-id" {
#   key             = "secret-id"
#   value           = "my_value_name"
#   category        = "terraform"
#   description     = "Approle secret-id for TF to use to connect to Vault"
#   variable_set_id = tfe_variable_set.tf_vault_creds.id
# }