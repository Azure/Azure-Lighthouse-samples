<#PSScriptInfo

.VERSION 1.4

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
November 11, 2020 1.4
    Fixed more issues with REST API logic due to updates to Az cmdlets
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

.EXAMPLE
  .\Remove-PolicyInitDeployment.ps1 -Environment AzureUSGovernment -subscriptionId 'fd2323a9-2324-4d2a-90f6-7e6c2fe03512' -ARMTemplate .\exporttest\ARM-Template-azurepolicyinit.json
  Does everything that the previous example does, only targets Azure Government Cloud

.NOTES
   AUTHOR: Jim Britt Principal Program Manager - Azure CXP API (Azure Product Improvement) 
   LASTEDIT: November 11, 2020 1.4
    Fixed more issues with REST API logic due to updates to Az cmdlets
    
   November 03, 2020 1.3
    Fixed a bug with REST API logic

   October 30, 2020 1.2 - Updates
    Changed REST API Token creation due to a recent breaking change I observed where the old way no longer worked.
    If you have any issues with this change, please let me know here on Github (https://aka.ms/AzPolicyScripts)

   August 4, 2020 1.1 - Updates
    Environment Added to script to allow for other clouds beyond Azure Commercial
    AzureChinaCloud, AzureCloud,AzureGermanCloud,AzureUSGovernment
    
    Special Thanks to Michael Pullen for your direct addition to the script to support
    additional Azure Cloud reach for this script! :) 
    
    Thank you Matt Taylor, Paul Harrison, and Abel Cruz for your collaboration in this area
    to debug, test, validate, and push on getting Azure Government supported with these scripts!

   June 06, 2020 1.0
   Initial
    * This script leverages an ARM Template used to deploy an Azure Policy Initiative and removes the deployed
    resources from your Azure Subscription

.LINK
    This script posted to and discussed at the following locations:
    https://aka.ms/AzPolicyScripts
#>

[CmdletBinding()]
param (
    # Determines which cloud to target - AzureCloud is default
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud",

    # An ARM Template file that was initially leveraged to deploy a policy initiative (and custom policies)
    [Parameter(Mandatory=$True)]
    [string]$ARMTemplate,

    # SubscriptionID to remove Policy Initiative (and custom policies) as long as not currently assigned
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

    # Establish REST Token
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)
}
catch
{
    $null = Login-AzAccount -Environment $Environment
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    
    # Establish REST Token
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)
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