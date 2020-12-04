<#PSScriptInfo

.VERSION 1.6

.GUID 5d5c9fe8-85a7-427d-88e7-6c44f61271ce

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
https://aka.ms/AzPolicyScripts

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
November 11, 2020 1.6
    Fixed more issues with REST API logic due to updates to Az cmdlets
#>

<#  
.SYNOPSIS  
  Create a set of remediation tasks across a scope (Subscription or Management Group) to remediate a Policy Initiative
  
.DESCRIPTION  
  This script takes a PolicyAssignmentId, SubscriptionID or ManagementGroupID as parameters, analyzes the scope targeted 
  to determine what Azure Policy Initiatives are available to remediate, and triggers the creation of these remediation tasks
  to the targeted scope. Leverage for -force switch to bypass the prompt at the end of script execution to ensure 
  select execution (given all parameters are provided)

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the Policy Initiative

.PARAMETER ManagementGroup
    This ManagementGroup switch can be used to change scope to Management Group for scanning for the policy initiative assignment
 
.PARAMETER ManagementGroupID
    This parameter can be provided along with the ManagementGroup switch to predefine which MG you want to scan.  If this parameter is not provided
    the list of Management Groups you have access to will be presented in a menu you can then select. 

.PARAMETER PolicyAssignmentId
    This parameter allows you to provide which Policy Assignment (for Policy Initiative) that you want to remediate

.PARAMETER ADO
    This parameter allows you to execute this script within an Azure DevOps Pipeline utilizing an SPN
    (no op - deprecated)

.EXAMPLE
  .\Trigger-PolicyInitiativeRemediation.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" 
  With a specified subscriptionID as scope, the script will prompt which policy assignment to select for remediation
  
.EXAMPLE
  .\Trigger-PolicyInitiativeRemediation.ps1
  Will prompt for subscriptionID to leverage for analysis and prompt for which Policy Initiative Assignment within the scope

.EXAMPLE
  .\Trigger-PolicyInitiativeRemediation.ps1 -ManagementGroup
  Will prompt for ManagementGroupId and PolicyAssignmentId to leverage for remediation

.EXAMPLE
  .\Trigger-PolicyInitiativeRemediation.ps1 -ManagementGroup -ManagementGroupId "MyManagementGroup" `
  -PolicyAssignmentId '/providers/Microsoft.Management/managementGroups/MyManagementGroup/providers/Microsoft.Authorization/policyAssignments/pa1' `
  -force

  Will remedate a policy initiaive given the ManagementGroupId as scope, the specific PolicytAssignmentId and use force to execute silently.

.EXAMPLE
  .\Trigger-PolicyInitiativeRemediation.ps1 -Environment AzureUSGovernment -ManagementGroup -ManagementGroupId "MyManagementGroup" `
  -PolicyAssignmentId '/providers/Microsoft.Management/managementGroups/MyManagementGroup/providers/Microsoft.Authorization/policyAssignments/pa1' `
  -force

  Will do everything the previous example accomplished but targeting AzureUSGovernment Cloud instead of AzureCloud

.NOTES
   AUTHOR: Jim Britt Principal Program Manager - Azure CXP API (Azure Product Improvement) 
   November 11, 2020 1.6
    Fixed more issues with REST API logic due to updates to Az cmdlets
    
   November 03, 2020 1.5
    Fixed a bug with REST API logic

   October 30, 2020 1.4
    Changed REST API Token creation due to a recent breaking change I observed where the old way no longer worked.
    If you have any issues with this change, please let me know here on Github (https://aka.ms/AzPolicyScripts)
    
   August 13, 2020 1.3
    Added parameter -ADO
    This parameter provides the option to run this script leveraging an SPN in Azure DevOps.

    Special Thanks to Nikolay Sucheninov and the VIAcode team for working to get these scripts
    integrated and operational in Azure DevOps to streamline "Policy as Code" processes with version
    drift detection and remediation through automation!

   August 4, 2020 1.2 - Updates
    Environment Added to script to allow for other clouds beyond Azure Commercial
    AzureChinaCloud, AzureCloud,AzureGermanCloud,AzureUSGovernment
    
    Special Thanks to Michael Pullen for your direct addition to the script to support
    additional Azure Cloud reach for this script! :) 
    
    Thank you Matt Taylor, Paul Harrison, and Abel Cruz for your collaboration in this area
    to debug, test, validate, and push on getting Azure Government supported with these scripts!

    Bug fix for enumeration and execution of remediation of Policy Initiatives when Management Group is used
    
   July 2, 2020 1.1 - Updates
    Small visual bug on variable prompt when providing PolicyAssignmentId parameter value

   July 1, 2020 1.0 - Initial

.LINK
    This script posted to and discussed at the following locations:
    https://aka.ms/AzPolicyScripts
#>

[cmdletbinding(
        DefaultParameterSetName='Default'
    )]

param
(
    # Determine which Azure Cloud to leverage for script - default is AzureCloud
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Initiative')]
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud",

    # Run inside Azure DevOps Pipeline with SPN Auth
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Initiative')]
    [Parameter(Mandatory=$false)]
    [switch]$ADO = $False,

    # Specify a policy initiative assignment ID
    # Example for Management Group Scope: '/providers/Microsoft.Management/managementGroups/MyManagementGroup/providers/Microsoft.Authorization/policyAssignments/pa1'
    # Example for Subscription Scope: '/subscriptions/fd2323a9-2324-4d2a-90f6-7e6c2fe03512/providers/Microsoft.Authorization/policyAssignments/17ddefc76ecd4fe5b26455bb'
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Initiative')]
    [string]$PolicyAssignmentId,

    # Management Group switch to allow for scanning all subs in a management group (instead of sub only)
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ManagementGroup=$False,

    # Management Group ID to scan (if left blank - will build list and prompt for selection if $ManagementGroup switch is used)
    [Parameter(ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupID,

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(ParameterSetName='Subscription')]
    [string]$SubscriptionId,

    # Use -force switch to bypass prompt to continue at end of script execution
    [switch]$Force=$False

)
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

# Build out the body for the GET / PUT request via REST API
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


# MAIN SCRIPT
$Start = $(Get-date)
if (!($MyInvocation.MyCommand.Path))
{
    $CurrentDir = Split-Path $MyInvocation.MyCommand.Path
}
else
{
    # Sometimes $myinvocation is null, it depends on the PS console host
    $CurrentDir = "."
}
Set-Location $CurrentDir

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

# Ensure this is the subscription where your Azure Policy Initiative is located
If($AzureLogin -and !($SubscriptionID) -and !($ManagementGroup))
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
if($SubscriptionId -and !($ManagementGroup))
{
    try{
        $SubscriptionToUse = Select-AzSubscription -Subscription $SubscriptionId
        Write-Host "Selecting Azure Subscription: $($SubscriptionToUse.Subscription.Name) ..." -ForegroundColor Cyan
    }
    catch{
        write-host "Something went wrong - please check subscriptionId and try again" -ForegroundColor Red
        break
    }
    
    
}

# If Management Group specified, but no ID provided, let's go get one to use
If(!($ManagementGroupID) -and $ManagementGroup)
{
    [array]$MgtGroupArray = Add-IndexNumberToArray (Get-AzManagementGroup)
    if(!$MgtGroupArray)
    {
        Write-host "Please make sure you have Management Groups that are accessible"
        exit 1
    }
    [int]$SelectedMG = 0

    # use the current Managment Group if there is only one MG available
    if ($MgtGroupArray.Count -eq 1) 
    {
        $SelectedMG = 1
    }
    # Get Management Group if one isn't provided
    while($SelectedMG -gt $MgtGroupArray.Count -or $SelectedMG -lt 1)
    {
        Write-host "Please select a Management Group from the list below"
        $MgtGroupArray | select-object "#", Name, DisplayName, Id | Format-Table
        try
        {
            write-host "If you don't see your ManagementGroupID try using the parameter -ManagementGroupID" -ForegroundColor Cyan
            $SelectedMG = Read-Host "Please enter a selection from 1 to $($MgtGroupArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($MgtGroupArray[$SelectedMG - 1].Name))
    {
        $ManagementGroupID = $($MgtGroupArray[$SelectedMG - 1].Name)
    }
    
    write-verbose "You Selected Management Group: $ManagementGroupID"
    Write-Host "Selecting Management Group: $ManagementGroupID ..." -ForegroundColor Cyan
}

# If Management Group specified, let's validate the ID provided is correct (exists)
if($ManagementGroup)
{
    $SubScriptionsToProcess =@()
    if($ManagementGroupID)
    {
        $azEnvironment = Get-AzEnvironment -Name $Environment
        $GetBody = BuildBody -method "GET"
        $MGSubsDetailsURI = "$($azEnvironment.ResourceManagerUrl)providers/microsoft.management/managementGroups/$($ManagementGroupID)/descendants?api-version=2018-03-01-preview"
        $GetResults = (Invoke-RestMethod -uri $MGSubsDetailsURI @GetBody).value
        foreach($Result in $GetResults| Where-Object {$_.type -eq "/subscriptions"})
        {
            $SubScriptionsToProcess += $Result 
        }
    }
    else {
        Write-Host "No ManagementGroupID found - ERROR!"
        write-host "Setting Context back to initial subscription $CurrentSub" -ForegroundColor Blue
        $Null = Set-AzContext -Subscription $CurrentSub
        break
    }
    
}
if($SubscriptionId)
{
    $Scope = "/subscriptions/$($SubscriptionToUse.Subscription.Id)"
}
if($ManagementGroupID)
{
    $Scope = "/providers/Microsoft.Management/managementgroups/$($ManagementGroupID)"
}

# If we don't have a PolicyAssignmentID to use, let's ask for one from the scope provided
$WarningPreference = "SilentlyContinue"
If(!($PolicyAssignmentID))
{
    try {
        [array]$PolicyAssignMentIDArray = Add-IndexNumberToArray (Get-AzPolicyAssignment -Scope $Scope | where-object {$_.Properties.policyDefinitionID -match 'policySetDefinitions'})     
    }
    catch {
        Write-Host "`nERROR: Please check that there are Policy Initiatives assigned to scope " -nonewline -ForegroundColor Red 
        write-host "$Scope" -NoNewline -ForegroundColor Yellow
        write-host " ...terminating script`n" -ForegroundColor Red
        write-host "Setting Context back to initial subscription $CurrentSub" -ForegroundColor Blue
        $Null = Set-AzContext -Subscription $CurrentSub
        break
    }
    [int]$SelectedAssignmentID = 0

    # use the only assignmentid if there is only one available
    if ($PolicyAssignMentIDArray.Count -eq 1) 
    {
        $SelectedAssignmentID = 1
    }
    # Get IDs if one isn't provided
    while($SelectedAssignmentID -gt $PolicyAssignMentIDArray.Count -or $SelectedAssignmentID -lt 1)
    {
        Write-host "Please select an AssignMentID from the list below"
        $PolicyAssignMentIDArray | Select-Object "#", @{Label = "PolicyAssignment Name";Expression={$_.Properties.displayName}}, @{Label = "PolicyAssignmentID";Expression={$_.ResourceId}} | Format-Table
        try
        {
            $SelectedAssignmentID = Read-Host "Please enter a selection from 1 to $($PolicyAssignMentIDArray.count)"
        }
        catch
        {
            Write-Warning -Message 'Invalid option, please try again.'
        }
    }
    if($($PolicyAssignMentIDArray[$SelectedAssignmentID - 1].Name))
    {
        $PolicyAssignmentID = $($PolicyAssignMentIDArray[$SelectedAssignmentID - 1].PolicyAssignmentId)
    }
    write-verbose "You Selected Azure Policy Initiative: $($PolicyAssignMentIDArray[$SelectedAssignmentID - 1].Properties.displayName)"
}
if($PolicyAssignmentID)
{
    try
    {
        $PolicyAssignment = Get-AzPolicyAssignment -Id $PolicyAssignmentID
        $PolicyDefinition = $(Get-AzPolicySetDefinition -id $PolicyAssignment.Properties.policyDefinitionId)
        $PolicyDefinitionRefIDs = $($PolicyDefinition.Properties.policyDefinitions).policyDefinitionReferenceId
        Write-Host "Selecting Azure Policy Initiative: $($PolicyAssignMent.Properties.displayName)..." -ForegroundColor Cyan
    }
    catch{
        write-host "Something went wrong - please check PolicyAssignmentID and try again" -ForegroundColor Red
        write-host "Setting Context back to initial subscription $CurrentSub" -ForegroundColor Blue
        $Null = Set-AzContext -Subscription $CurrentSub
        break
    }
}

# Initialize counts to track number of policies to remediate
$Count = 0
$Totalcount = $PolicyDefinitionRefIDs.Count

# Use -force switch to bypass prompt
if ($Force -OR $PSCmdlet.ShouldContinue("Create a set of remediation tasks for Policy Initiative `"$($PolicyAssignMent.Properties.displayName)`". Continue?","Remediate `"$($PolicyAssignMent.Properties.displayName)`" Initiative?") )
{
    Foreach($PolicyDefRefID in $PolicyDefinitionRefIDs)
    {
        try {
            $Count++
            write-host "Creating remediation for Policy $Count of $Totalcount - Remediation-$PolicyDefRefID"
            $null = Start-AzPolicyRemediation -PolicyAssignmentId $PolicyAssignmentID -PolicyDefinitionReferenceId $PolicyDefRefID -Name "Remediation-$PolicyDefRefID"
        }
        catch {
            Write-Host "Something went wrong creating the policy remediation" -ForegroundColor Red
            write-host "Setting Context back to initial subscription $CurrentSub" -ForegroundColor Blue
            $Null = Set-AzContext -Subscription $CurrentSub
            break
        }
    }
}
else {
    Write-Host "You have cancelled the remediation request for $($PolicyAssignMent.Properties.displayName)" -ForegroundColor Yellow
}

# Stop "timer" to calculate total time running
$Stop = (Get-Date)

# Let's set context back to original sub you were on before executing
write-host "Setting Context back to initial subscription $CurrentSub" -ForegroundColor Blue
try
{
    $Null = Set-AzContext -Subscription $CurrentSub
}
catch
{
    Write-Host "Failed to set context back to intial subscription $CurrentSub.  Please review!"
}

# Finish up
Write-Host "Complete`n" -ForegroundColor Green
Write-Host "Script execution time: " -nonewline
Write-Host "$($($Stop - $Start).minutes) minutes and $($($Stop - $Start).seconds) seconds.`n" -ForegroundColor Cyan