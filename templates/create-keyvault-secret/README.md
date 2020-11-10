# Create a Key Vault that grants Managed Identity access to secrets

Often times a provider in Azure Lighthouse would need to store keys or secrets in Azure Key Vault so that their applications can access them securely with [Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) (MI). This can be done in the provider's context without logging into the customer's tenant.

This example demonstrates:

1. How to [create a Key Vault in the customer's tenant](createKeyVaultSecret.json#L41). Note that you need to [specify the customer's tenant ID](createKeyVaultSecret.json#L49) during Key Vault creation, otherwise, the Key Vault is created in the provider's tenant by default.
2. How to [create an access policy for the managed identity of a web app](createKeyVaultSecret.json#L52) in the customer's tenant so that the web app can read the secrets.
3. How to [set secret in the Key Vault](createKeyVaultSecret.json#L70) created above using [Microsoft.KeyVault/vaults/secrets](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets#microsoftkeyvaultvaultssecrets-object) **write** action which provider's identity can perform via ARM if it has "Contributor" or "Key Vault Contributor" role on the Azure Key Vault resource.

> Note: Using the ARM control-plane approach above, the provider can set/write secrets into customer's Azure Key Vault but cannot list/read these secrets using the provider's context since provider's identity is not in the customer's tenant. On the other hand, the web app will be able to read the secrets since its managed identity is in the customer's tenant and that managed identity is provided data-plane access via Key Vault [accessPolicies](createKeyVaultSecret.json#L51).
