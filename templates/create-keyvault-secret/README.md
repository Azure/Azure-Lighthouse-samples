# Create a Key Vault that grants MSI access to secrets

Often times a provider in Azure Lighthouse would need to store keys or secrets in Azure Key Vault so that their applications can access them securely with [Managed Service Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) (MSI).  This can be done in the provider's context without logging into the customer's tenant.

This example demonstrates:
1. how to [create a Key Vault in the customer's tenant](createKeyVaultSecret.json#L47). Note that you need to [specify the customer's tenant ID](createKeyVaultSecret.json#L55) during Key Vault creation, otherwise, the Key Vault is created in the provider's tenant by default. 
2. how to [create an access policy for a principal](createKeyVaultSecret.json#L58) in the provider's tenant so that the provider can create secrets. 
3. how to [create an access policy for the MSI of a web app](createKeyVaultSecret.json#L65) in the customer's tenant so that the web app can read the secrets.
4. how to [put a secret in the Key Vault](createKeyVaultSecret.json#L83) created above.
