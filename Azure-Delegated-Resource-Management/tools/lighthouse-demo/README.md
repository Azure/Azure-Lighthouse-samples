# Azure Lighthouse demo script

This Powershell script will walk through some of the management capabilities in Lighthouse, in a multi-tenant/cross-tenant scenario.

1. Query across all tenants and their delegated scope using Azure Resource Graph
2. Get all delegated subscriptions
3. Deploy a new policy definition and assignment across all delegated subscriptions
4. Validate the policy is effective, by making a test deployment
5. Clean up: Remove the policy assignment and deployment

## Powershell sample

````
# Using Resource Graph to detect storage accounts not being secured by https

Search-AzGraph -Query "summarize count() by tenantId" | ConvertTo-Json

Search-AzGraph -Query "where type =~ 'Microsoft.Storage/storageAccounts' | project name, location, subscriptionId, tenantId, properties.supportsHttpsTrafficOnly" | convertto-json

# Deploying Azure Policy using ARM templates at scale across multiple customer scopes, to deny creation of storage accounts not using https

$subs = Get-AzSubscription

Write-Output "In total, there's $($subs.Count) projected customer subscriptions to be managed"

foreach ($sub in $subs)
{
    Select-AzSubscription -SubscriptionId $sub.id

    New-AzDeployment -Name mgmt `
                     -Location eastus `
                     -TemplateUri "https://raw.githubusercontent.com/krnese/AzureDeploy/master/ARM/deployments/PCI/Enforce-HTTPS-Storage-DENY.json" `
                     -AsJob
}

# Validating the policy - deny creation of storage accounts that are NOT using https only

New-AzStorageAccount -ResourceGroupName (New-AzResourceGroup -name kntest -Location eastus -Force).ResourceGroupName `
                     -Name (get-random) `
                     -Location eastus `
                     -EnableHttpsTrafficOnly $false `
                     -SkuName Standard_LRS `
                     -Verbose
                     
# clean-up

foreach ($sub in $subs)
{
    select-azsubscription -subscriptionId $sub.id

    Remove-AzDeployment -Name mgmt -AsJob

    $Assignment = Get-AzPolicyAssignment | where-object {$_.Name -like "enforce-https-storage-assignment"}

    if ([string]::IsNullOrEmpty($Assignment))
    {
        Write-Output "Nothing to clean up - we're done"
    }
    else
    {
    Remove-AzPolicyAssignment -Name 'enforce-https-storage-assignment' -Scope "/subscriptions/$($sub.id)" -Verbose

    Write-Output "ARM deployment has been deleted - we're done"
    }
}
```