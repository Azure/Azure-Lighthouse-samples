<#PSScriptInfo

.VERSION 1.4

.GUID efd1a650-e9e6-4cd3-beca-cc0e940cc672

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
  Use this script to trigger the Azure Policy Evaluation API
     
.DESCRIPTION  
  This script takes a SubscriptionID and optionally a ResourceGroup as parameters, allows you to also specify an interval
  for how many seconds you want to delay before checking status of the policy evaluation (default is 20 seconds)

  Based on the API documented here: https://docs.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data#evaluation-triggers

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the policies to evaluate

.PARAMETER ResourceGroupName
    If desired, use a resourcegroup in addition to SubscriptionID to narrow in on a scope of ResourceGroup to evaluate policy compliance 

.PARAMETER Interval
    Specify an interval in seconds (default is 20) to check for status of trigger - loops until complete.

.PARAMETER ADO
    This parameter allows you to run this script in Azure DevOps pipeline utilizing an SPN
    (no op - deprecated)

.EXAMPLE
  .\Trigger-PolicyEvaluation.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceGroup "RGName" interval 25
  Trigger evaluation against the scope of a Resource Group, with a specified subscriptionID with an interval of 25 seconds

.EXAMPLE
  .\Trigger-PolicyEvaluation.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512"
  Trigger evaluation against the scope of a subscriptionID

.EXAMPLE
  .\Trigger-PolicyEvaluation.ps1
  Prompt for a subscriptionId from a menu listing of all available subscriptions within the context of the logged in user.
  Trigger evaluation against the scope of a subscriptionID selected.

.NOTES
   AUTHOR: Jim Britt Principal Program Manager - Azure CXP API (Azure Product Improvement) 
   LASTEDIT: November 11, 2020 1.4
    Fixed more issues with REST API logic due to updates to Az cmdlets

   November 03, 2020 1.3
    Fixed a bug with REST API logic

   October 30, 2020 1.2 - Updates
    Changed REST API Token creation due to a recent breaking change I observed where the old way no longer worked.
    If you have any issues with this change, please let me know here on Github (https://aka.ms/AzPolicyScripts)

   August 13, 2020 1.1
    Added parameter -ADO
    This parameter provides the option to run this script leveraging an SPN in Azure DevOps.

    Special Thanks to Nikolay Sucheninov and the VIAcode team for working to get these scripts
    integrated and operational in Azure DevOps to streamline "Policy as Code" processes with version
    drift detection and remediation through automation!

   May 01, 2019
    Initial

.LINK
    This script posted to and discussed at the following locations:
    https://github.com/JimGBritt/AzurePolicy/tree/master/AzureMonitor/Scripts 
#>

param
(
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud",

    [Parameter(Mandatory = $False)]
    [switch]$ADO = $False,

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(Mandatory = $False)]
    [guid]$SubscriptionId,

    # Add a ResourceGroup name to reduce scope from entire Azure Subscription to RG
    [Parameter(Mandatory = $False)]
    [string]$ResourceGroupName,

    # An interval in seconds to check that trigger was successful
    [Parameter(Mandatory = $False)]
    [int]$interval = 20

)
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
function BuildBody
(
    [parameter(mandatory=$True)]
    [string]$method
)
{
    $BuildBody = @{
    Headers = @{
        Authorization = "Bearer $($token.AccessToken)"
        'Content-Type' = 'application/json'
    }
    Method = $Method
    UseBasicParsing = $true
    }
    $BuildBody
}  
# Login to Azure - if already logged in, use existing credentials.
If($ADO){write-host "ADO switch deprecated and no longer necessary" -ForegroundColor Yellow}
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

If($AzureLogin -and !($SubscriptionID))
{
    [array]$SubscriptionArray = Add-IndexNumberToArray (Get-AzSubscription) 
    [int]$SelectedSub = 0

    # use the current subscription if there is only one subscription available
    if ($SubscriptionArray.Count -eq 1) 
    {
        $SelectedSub = 1
    }
    # Get SubscriptionID if one isn't provided
    while($SelectedSub -gt $SubscriptionArray.Count -or $SelectedSub -lt 1)
    {
        Write-host "Please select a subscription from the list below"
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
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].Name)
    }
    elseif($($SubscriptionArray[$SelectedSub - 1].SubscriptionName))
    {
        $SubscriptionName = $($SubscriptionArray[$SelectedSub - 1].SubscriptionName)
    }
    write-verbose "You Selected Azure Subscription: $SubscriptionName"
    
    if($($SubscriptionArray[$SelectedSub - 1].SubscriptionID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].SubscriptionID)
    }
    if($($SubscriptionArray[$SelectedSub - 1].ID))
    {
        [guid]$SubscriptionID = $($SubscriptionArray[$SelectedSub - 1].ID)
    }
}
Write-Host "Selecting Azure Subscription: $($SubscriptionID.Guid) ..." -ForegroundColor Cyan
$Null = Select-AzSubscription -SubscriptionId $SubscriptionID.Guid

$PostBody = BuildBody -method "POST"
#Establish URI to gather resources
$Subscription = $(Get-AzContext).Subscription.id 

If($SubscriptionId -and !($ResourceGroupName))
{
    write-host "No Resourcegroup provided as a parameter ... triggering against subscription: $SubscriptionId" -ForegroundColor Yellow
    $RESOURCEID = "/subscriptions/$Subscription"
}
elseif ($ResourceGroupName)
{
    write-host "ResourceGroup provided ... triggering against resource group name:$ResourceGroupName" -ForegroundColor Yellow
    $RESOURCEID = "/subscriptions/$Subscription/$ResourceGroup"

}
$azEnvironment = Get-AzEnvironment -Name $Environment
$PostURI = "$($azEnvironment.ResourceManagerUrl)$RESOURCEID/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"

try
{
    $PostRAW = $(Invoke-WebRequest -uri $PostURI @PostBody).Rawcontent
    Write-Host "Submitted Policy Evaluation Trigger Request" -foregroundcolor Yellow
}
catch 
{
    "Error"
    exit
}

$PostArray = $PostRaw.Split("`n")
[string]$LocationVar = $($PostArray|Select-String -SimpleMatch "Location")
$GetURI = $($LocationVar.Split(" ",2))[1]
$GetBody = BuildBody -method "GET"

$GetResults = Invoke-WebRequest -uri $GetURI @GetBody
while($GetResults.StatusCode -ne 200)
{
   $GetResults = Invoke-WebRequest -uri $GetURI @GetBody
   Write-Host "Status code $($GetResults.Statuscode) returned on query.  Still in progress...waiting $interval seconds to requery" 
   start-sleep $interval
}

Write-Host "Successfully Triggered a Policy Evaluation Request" -foregroundcolor Cyan
