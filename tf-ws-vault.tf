# # resource "tfe_organization" "vault" {
# #   name  = "vault"
# #   email = var.email
# # }

# # resource "tfe_oauth_client" "test" {
# #   organization     = tfe_organization.test-organization
# #   api_url          = "https://api.github.com"
# #   http_url         = "https://github.com"
# #   oauth_token      = "oauth_token_id"
# #   service_provider = "github"
# # }

# # resource "tfe_workspace" "parent" {
# #   name                 = "parent-ws"
# #   organization         = tfe_organization.test-organization
# #   queue_all_runs       = false
# #   vcs_repo {
# #     branch             = "main"
# #     identifier         = "my-org-name/vcs-repository"
# #     oauth_token_id     = tfe_oauth_client.test.oauth_token_id
# #   }
# # }

# data "remote_file" "vault_issuer_ca" {
#   conn {
#       user        = values(module.vault_hosts_public)[0].username #should only be one public host
#       private_key = tls_private_key.ssh_allhosts.private_key_pem
#       host        = values(module.vault_hosts_public)[0].public_ip_address
#     }

#   path = "/home/vault/certs/issuing_ca_b64.txt" #base64 encoded version of the PEM issuing CA cert

#   lifecycle {
#     # The EC2 instance will have an encrypted root volume.
#     postcondition {
#       condition     = null_resource.bootstrap_ansible.id != ""
#       error_message = "Ansible needs to create the base64 encoded issuing ca file first before it can be accessed"
#     }
#   }
# }

# resource "tfe_workspace" "vault" {
#   name         = "vault-ws"
#   organization = var.tfe_organization
# }


# resource "tfe_variable" "tfc_vault_auth_path" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_AUTH_PATH"

#   # Replace this with the name and path to your certificate
#   value     = "tfc"
#   category  = "env"
#   sensitive = false

#   description = "The path to use for the auth method configured in Vault for Terraform Workload Identity (this is consfigured in Ansible)"
# }

# resource "tfe_variable" "tfc_vault_run_role" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_RUN_ROLE"

#   # Replace this with the name and path to your certificate
#   value     = "terraform"
#   category  = "env"
#   sensitive = false

#   description = "The role to use for JWT Workload Identity auth to Vault (configured in Ansible)"
# }

# resource "tfe_variable" "tfc_vault_provider_auth" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_PROVIDER_AUTH"

#   # Replace this with the name and path to your certificate
#   value     = "true"
#   category  = "env"
#   sensitive = false

#   description = "Enable Workload Identity for Terraform to be able to authenticate to Vault"
# }

# resource "tfe_variable" "tfc_vault_workload_identity_audience" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_WORKLOAD_IDENTITY_AUDIENCE"

#   # Replace this with the name and path to your certificate
#   value     = "tfc"
#   category  = "env"
#   sensitive = false

#   description = "The JWT audience value to use (configured in Ansible)"
# }

# resource "tfe_variable" "tfc_vault_addr" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_ADDR"

#   value     = "https://${azurerm_public_ip.vault_public_ip.ip_address}:8200"
#   category  = "env"
#   sensitive = false

#   description = "Public IP of the Vault server (this will need reset each time the Azure host is restarted)"
# }

# resource "tfe_variable" "tfc_vault_encoded_cacert" {
#   workspace_id = tfe_workspace.vault.id #tfe_workspace.my_workspace.id

#   key = "TFC_VAULT_ENCODED_CACERT"

#   # Replace this with the name and path to your certificate
#   value     = data.remote_file.vault_issuer_ca.content
#   category  = "env"
#   sensitive = false

#   description = "A Base64 encoded CA certificate to use when authenticating with Vault"
# }