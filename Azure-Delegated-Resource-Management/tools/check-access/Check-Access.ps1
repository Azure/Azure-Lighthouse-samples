<#
.SYNOPSIS
    Check the current user's access to a Subscription

.DESCRIPTION
  This script takes a subscription as a parameter and displays the user's role assignments on a given Azure subscription.
 
.PARAMETER Subscription
    The subscriptionID or subscriptionName of the Azure Subscription for which you want to check permissions.
 
.EXAMPLE
  .\Check-Owner.ps1 "your subscription name or guid here"
   
.EXAMPLE
  .\Check-Owner.ps1 
  Will prompt to select from your subscriptions
 
.NOTES 
   Thanks to Jim Britt, the author of the source of most of this script: https://www.powershellgallery.com/packages/Create-AzDiagPolicy/1.4/Content/Create-AzDiagPolicy.ps1
#>

[cmdletbinding(
        DefaultParameterSetName='Default'
    )]
 # Provide Subscription to bypass subscription listing
param($Subscription)

# FUNCTIONS

# Function used to build numbers in selection tables for menus
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

# MAIN SCRIPT

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
}
Write-Host "Current user: $($currentContext.Account.Id)"

if(!($AzureLogin)) 
{
    Write-Host "You do not have access to any subscriptions." 
    exit
}
# Select provided subscription 
if($Subscription)
{
    Write-Host "Selecting Azure Subscription: $Subscription ..." -ForegroundColor Cyan
    $isValid = Select-AzSubscription $Subscription
    if(!($isValid)) {
        $Subscription = $null
    }
}
# Prompt with menu of subscriptions 
if (!($Subscription))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    # Prompt user to select Subscription if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "You have access to these subscriptions: "
        $SubscriptionArray | Select-Object "#", Id, Name | Format-Table
        try
        {
            $SelectedSub = Read-Host "Please enter a selection from 1 to $($SubscriptionArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($SubscriptionArray[$SelectedSub - 1].Name))
    {
        $Subscription = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $Subscription = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    Write-Host "Selecting Azure Subscription: $Subscription ..." -ForegroundColor Cyan
    $null = Select-AzSubscription $Subscription
}

# Check access
Get-AzRoleAssignment -SignInName $currentContext.Account.Id -ExpandPrincipalGroups | FT RoleDefinitionName, DisplayName, Scope

Write-Host "Complete" -ForegroundColor Green