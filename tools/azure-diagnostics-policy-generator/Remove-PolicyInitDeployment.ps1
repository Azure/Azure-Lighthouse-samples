<#PSScriptInfo

.VERSION 1.0

.GUID 4071a36f-de54-4efb-a706-ea2ca98ced49

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
https://github.com/JimGBritt/AzurePolicy/tree/master/AzureMonitor/Scripts

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
June 06, 2020 1.0
Initial
 * This script leverages an ARM Template used to deploy an Azure Policy Initiative and removes the deployed
   resources from your Azure Subscription
 #>

<#  
.SYNOPSIS  
Remove an Azure Policy Initiative from an Azure Subscription using an ARM Template reference

.DESCRIPTION  
  This script takes a SubscriptionID, and ARMTemplate as parameters, to remove a deployed 
  Azure Policy Initiative and set of custom policies based on an Azure Policy Initiative ARM Template

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the resources you want to remove

.PARAMETER ARMTemplate
    The ARM template that has references to the Policy Initiative and dependent custom policies
    
.EXAMPLE
  .\Remove-PolicyInitDeployment.ps1 -subscriptionId 'fd2323a9-2324-4d2a-90f6-7e6c2fe03512' -ARMTemplate .\exporttest\ARM-Template-azurepolicyinit.json
  Removed a Policy Initiative and Dependent Custom Policies referenced in a supplied ARM template within a specified subscriptionID as scope
  
.NOTES
   AUTHOR: Jim Britt Senior Program Manager - Azure CXP API (Azure Product Improvement) 
   LASTEDIT: June 06, 2020 1.0

   Initial
    * This script leverages an ARM Template used to deploy an Azure Policy Initiative and removes the deployed
    resources from your Azure Subscription

.LINK
    This script posted to and discussed at the following locations:
    https://aka.ms/AzPolicyScripts
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [string]$ARMTemplate,
    [Parameter(Mandatory=$True)]
    [guid]$subscriptionId
)
$ARMTemplateToProcess = Get-Content $ARMTemplate
$ResultSet = $ARMTemplateToProcess | ConvertFrom-Json
$Initiative = $($ResultSet.resources | Where-Object {$_.type -eq "Microsoft.Authorization/policySetDefinitions"})
$Policies = $($ResultSet.resources | Where-Object {$_.type -ne "Microsoft.Authorization/policySetDefinitions"})

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $currentSub = $(Get-AzContext).Subscription.Name
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 
    if($Token.ExpiresOn -lt $(get-date))
    {
        "Logging you out due to cached token is expired for REST AUTH.  Re-run script"
        $null = Disconnect-AzAccount        
        break
    } 
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 
    break

}

Try
{
    $Subscription = Get-AzSubscription -SubscriptionId $subscriptionId
}
catch
{
    Write-Host "Subscription not found"
    break
}


if ($PSCmdlet.ShouldContinue("This is destructive. We are about to delete Custom Policy Initiative `"$($Initiative.Properties.displayname)`" and $($Policies.count) Custom Policy resources from your subscription $SubscriptionId. Continue?","Remove `"$($Initiative.Properties.displayname)`" Initiative?") )
{
    try
    {
        Write-host "Now removing Policy Initiative `"$($Initiative.Properties.displayname)`""
        try {
            $Assignment = Get-AzPolicyAssignment -PolicyDefinitionId $(Get-AzPolicySetDefinition -Name $Initiative.Name).PolicysetdefinitionID
        }
        catch {
            
        }
        If(!($Assignment))
        {
            $Null = Remove-AzPolicySetDefinition -Name $($Initiative.name) -SubscriptionId $subscriptionId -Force
        }
        else {
            Write-Host "`nRemove Policy Initiative Assignment `"$($Assignment.Properties.displayName)`" before continuing!`n" -ForegroundColor Red
            break
        }
        foreach($Policy in $Policies)
        {
            try 
            {
                Write-host "Now removing Custom Policy `"$($Policy.Properties.displayname)`""
                $Null = Remove-AzPolicyDefinition -Name $Policy.name -SubscriptionId $subscriptionId -Force
            }
            catch {
                Write-Host "Something went wrong!" -ForegroundColor Red
                break                
            }
            
        }    
    }
    catch{
        Write-Host "Something went wrong!" -ForegroundColor Red
        break
    }
}
else {
    Write-Host "You cancelled"    
}
Write-Host "Complete!" -ForegroundColor Green