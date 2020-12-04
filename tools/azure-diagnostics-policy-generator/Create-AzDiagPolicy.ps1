<#PSScriptInfo

.VERSION 2.6

.GUID e0962947-bf3c-4ed4-be3b-39cb7f6348c6

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
November 11, 2020 2.6
    Fixed more issues with REST API logic due to updates to Az cmdlets
#>

<#  
.SYNOPSIS  
  Create a custom policy (and optional Policy Initative) to enable Azure Diagnostics and send that data to a Log Analytics Workspace, Regional Storage Account or Regional Event Hub
  
  Note  This script currently supports onboarding Azure resources that support Azure Diagnostics (metrics and logs) to Log Analytics, Event Hub, and Storage
  
.DESCRIPTION  
  This script takes a SubscriptionID, ResourceType, ResourceGroup as parameters, analyzes the subscription or
  specific ResourceGroup defined for the resources specified in $Resources, and builds a custom policy for 
  diagnostic metrics/logs for Event Hubs, Storage and Log Analytics as sink points for selected resource types.

.PARAMETER ManagementGroupDeployment
    Leverage this switch to export the ARM template for your policy initiative to
    support Management Group as a scope target.  This will place all resources (Custom Policies and Policy Initiative)
    in the same MG upon deployment via "New-AzManagementGroupDeployment"
    Ex: New-AzManagementGroupDeployment -Name DiagAzurePolicyInit -ManagementGroupId CatDev -Location eastus -TemplateFile .\MgTemplateExportMG.json -ManagementGroupDeployment -TargetMGID CatDev

.PARAMETER Environment
    The cloud environment that you are needing to analyze. Default is AzureCloud
    Available clouds: AzureChinaCloud, AzureCloud,AzureGermanCloud,AzureUSGovernment  

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the resources you want to analyze

.PARAMETER ResourceType
    The ResourceType you want to create a policy for within your Azure Subscription
    
.PARAMETER ResourceGroupName
    If desired, use a resourcegroup instead of analyzing all resources within an Azure subscription 

.PARAMETER ResourceName
    If desired, use a resource name instead of analyzing all resources within an Azure subscription

.PARAMETER ExportDir
    Directory to export policies to.  If not used, the working directory of the script will be leveraged as the export directory base folder

.PARAMETER ExportAll
    Parameter used to bypass the prompt for resource types to export policies for.  THis parameter if used will export all resource type policies

.PARAMETER ExportLA
    Export only Log Analytics policies for Azure Diagnostics

.PARAMETER ExportEH
    Export only Event Hub Policies for Azure Diagnostics

.PARAMETER ExportStorage
    Export only Storage Policies for Azure Diagnostics

.PARAMETER ValidateJSON
    If specified will do a post export validation recursively against the export directory or will validate JSONs recursively in current script
    directory and subfolders or exportdirectory (if specified).

.PARAMETER Tenant
    Use the -Tenant parameter to bypass the subscriptionID requirement
    Note: Cannot use in conjunction with -SubscriptionID

.PARAMETER LogPolicyOnly
    Use the -LogPolicyOnly parameter to export Azure Policies for resourceTypes that support Logs (bypass those that only support Metrics)

.PARAMETER AllRegions
    This AllRegions switch can be used to bypass the "location" check / parameter in the Azure Policies for Log Analytics.  
    Note: This switch does not support EventHub/Storage based policies due to the region requirement for EventHubs/Storage and Azure Diagnostic settings
 
.PARAMETER ManagementGroup
    This ManagementGroup switch can be used to change scope for scanning for resourceTypes that suppport Azure Diags to be at the Management Group
 
.PARAMETER ManagementGroupID
    This parameter can be provided along with the ManagementGroup switch to predefine which MG you want to scan.  If this parameter is not provided
    the list of Management Groups you have access to will be presented in a menu you can then select. 

.PARAMETER ExportInitiative
    This ExportInitiative Switch determines if you are exporting a Policy Initiative (ARM Template) or just raw policy files

.PARAMETER InitiativeDisplayName
    This parameter allows you to set the Policy Initiative Name so you can have two Initiatives with slighly different 
    names leveraging the same Custom Policies underneath.  Not the policy names and Initiatives are hash values according to the
    display name leveraged and the sink point used. Not the display name is limited to 127 chars (see https://aka.ms/AzureLimits)

.PARAMETER TemplateFileName
    This parameter allows you to determine the outputted ARM template file name for your policy initiative. This can be useful when
    leveraged with an ADO pipeline and test automation to validate policy drift according to a baselined exported Policy Initiatve that
    has been promoted into production versus what your environment states it should be configured as (at current state of running the script)

.PARAMETER ADO
    This parameter allows you to run this script in Azure DevOps pipeline utilizing an SPN
    (no op - deprecated)

.EXAMPLE
  .\Create-AzDiagPolicy.ps1 -SubscriptionId "fd2323a9-2324-4d2a-90f6-7e6c2fe03512" -ResourceType "Microsoft.Sql/servers/databases" -ResourceGroup "RGName" -ExportLA -ExportEH
  Take in parameters and execute silently without prompting against the scope of a resourceType, Resource Group, with a specified subscriptionID as scope
  
.EXAMPLE
  .\Create-AzDiagPolicy.ps1 -ExportLA
  Will prompt for subscriptionID to leverage for analysis, prompt for which resourceTypes to export for policies, and export the policies specific
  to Log Analytics only

.EXAMPLE
  .\Create-AzDiagPolicy.ps1 -ExportEH
  Will prompt for subscriptionID to leverage for analysis, prompt for which resourceTypes to export for policies, and export the policies specific
  to Event Hub only

.EXAMPLE
  .\Create-AzDiagPolicy.ps1 -ExportStorage
  Will prompt for subscriptionID to leverage for analysis, prompt for which resourceTypes to export for policies, and export the policies specific
  to Storage account only  

.EXAMPLE
  .\Create-AzDiagPolicy.ps1 -ValidateJSON -ExportDir "EH-Policies"
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportEH -ExportLA -ValidateJSON -Tenant -ExportDir ".\LogPolicies"
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors.  This example also provides the ability to go against the
  entire Azure AD Tenant as opposed to a single subscription

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -LogPolicyOnly -ExportAll -ExportEH -ExportLA -ValidateJSON -Tenant -ExportDir ".\LogPolicies"
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors.  This example also provides the ability to go against the
  entire Azure AD Tenant as opposed to a single subscription.  Exports Log Policies (metric check is bypassed)

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportEH -ExportLA -ValidateJSON -ExportDir ".\LogPolicies" -Tenant -AllRegions
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors.  This example also allows for bypassing the location specific 
  requirements for the exported Log Analytics policies. The scope for this export will be at the Azure AD tenant level.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportEH -ExportLA -ValidateJSON -ExportDir ".\LogPolicies" -ManagementGroup -AllRegions
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors.  This example also allows for bypassing the location specific 
  requirements for the exported Log Analytics policies. The scope for this export will be at the Management Group level.  If
  ManagementGroupID is left off, a menu will be provided during execution of the script to select one.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportLA -ValidateJSON -ExportDir ".\LogPolicies" -ManagementGroup -AllRegions -ExportInitiative
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors.  This example also allows for bypassing the location specific 
  requirements for the exported Log Analytics policies. The scope for this export will be at the Management Group level.  If
  ManagementGroupID is left off, a menu will be provided during execution of the script to select one. Finally, this example provides the
  ability to take the custom policies and write them to an ARM template Policy Initiative.  Note: you can only provide -ExportLA or -ExportEH
  (not both) as the policy initiative requires unique parameters on assignment to coincide with the sink point you are leveraging.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportLA -ValidateJSON -ExportDir ".\LogPolicies" -ManagementGroup -AllRegions -ExportInitiative -InitiativeDisplayName "Azure Diagnostics Policy Initiative for a Log Analytics Workspace" -TemplateFileName 'ARMTemplateExport'
  Similar to the previous example, this one adds additional capability of allowing you to define the display name for the Policy Initiative 
  as well as predetermine the templatefile name for the Policy Initiative.  Note the display name is validated that it is less than 127 chars long
  if provided.  Script will break if that value is either exceeded of the value is less than 1 char.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportAll -ExportStorage -ValidateJSON -ExportDir ".\LogPolicies" -ManagementGroup -AllRegions -ExportInitiative -InitiativeDisplayName "Azure Diagnostics Policy Initiative for a Regional Storage Account" -TemplateFileName 'ARMTemplateExport'
  Same as previous example, but exporting to a storage account as a sink point.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -Environment AzureUSGovernment -ExportAll -ExportStorage -ValidateJSON -ExportDir ".\LogPolicies" -ManagementGroup -AllRegions -ExportInitiative -InitiativeDisplayName "Azure Diagnostics Policy Initiative for a Regional Storage Account" -TemplateFileName 'ARMTemplateExport'
  Same as previous example, but leveraging Azure Government Cloud.

.EXAMPLE
.\Create-AzDiagPolicy.ps1 -ExportDir .\LogPolicies -ExportAll -ExportLA -ExportInitiative -TemplateFileName MgTemplateExportMG -ManagementGroupDeployment -AllRegions
  Exports an ARM Template Policy Initiative supporting a Management Group supporting all Logs for Log Analytics and all regions supported
  NOTE: Use the following example to deploy this template to a target management group

  New-AzManagementGroupDeployment -Name DiagAzurePolicyInit -ManagementGroupId MyMGID -Location eastus -TemplateFile .\MgTemplateExportMG.json -TargetMGID MyMGID

.NOTES
   AUTHOR: Jim Britt Principal Program Manager - Azure CXP API (Azure Product Improvement) 
   LASTEDIT: November 11, 2020 2.6
    Fixed more issues with REST API logic due to updates to Az cmdlets
    
   November 03, 2020 2.5
    Fixed a bug with REST API logic

   October 30, 2020 2.4
    Added parameter -ManagementGroupDeployment for ARM Export
    This parameter switch provides the option to export an ARM Template Policy Initiative that supports a Management
    group target scope.

    Special Thanks to Kristian Nese (https://github.com/krnese) for my sounding board and using his big brain to work through some of the ARM goo.
    Thank you Kamil (https://github.com/kwiecek) to for pushing for this feature to help improve the experience for our customersk leveraging it 
    and actively collaborating on improving our final enhancement!
    
    Thank you Dimitri Lider (https://github.com/dimilider) for the additional collaboration and also looking out for improving this script!

    Changed REST API Token creation due to a recent breaking change I observed where the old way no longer worked.
    If you have any issues with this change, please let me know here on Github (https://aka.ms/AzPolicyScripts)

   August 13, 2020 2.3
    Added parameter -ADO
    This parameter provides the option to run this script leveraging an SPN in Azure DevOps.

    Special Thanks to Nikolay Sucheninov and the VIAcode team for working to get these scripts
    integrated and operational in Azure DevOps to streamline "Policy as Code" processes with version
    drift detection and remediation through automation!

   August 03, 2020 2.2
    Environment Added to script to allow for other clouds beyond Azure Commercial
    AzureChinaCloud, AzureCloud,AzureGermanCloud,AzureUSGovernment
    
    Special Thanks to Michael Pullen for your direct addition to the script to support
    additional Azure Cloud reach for this script! :) 
    
    Thank you Matt Taylor, Paul Harrison, and Abel Cruz for your collaboration in this area
    to debug, test, validate, and push on getting Azure Government supported with these scripts!

    Fixed Bug with "Kind" and not exporting all policies for ResourceProviders that leverage
    Kind with same RP (ex: Azure SQL DB, Azure SQL DW)

    Special Thanks to Mo Barry for helping me isolate this bug in the script

   July 16, 2020 2.1
    Storage Added as a sink to policy and policy initiative ARM template exports

   June 07, 2020 2.0
    Significant Updates this version which pushed it to 2.0!
    * Special thanks to Dimitri Lider, and Julian Hayward (Microsoft) once again for their constant inputs on this script to improve! 

    * A HUGE THANK YOU to the ClearDATA crew for their support in bug bashing an early iteration of this 2.0 ver script before going broadly. 
    -- Thank you Jason Singh for leaning in on support for prioritizing review of this effort 
    -- And for Rob Sanders (https://github.com/rwsanders) for his isolation of a breaking bug I introduced that was much more easily isolated and resolved with his support!

    * Another special call out to Kristian Nese @KristianNese (https://github.com/krnese) and Chris Eggert (https://github.com/pilor) @pilor 
    * for their technical review and big brain guidance related to approach and technical accuracy in the area of ARM and Policy! 

    Policy Initiative Support
    - Added support for exporting to ARM Template Policy Initiative Artifact
    -- Option for customized displayname for Initiative
    -- Ability for Custom Azure Policies and Initiative to be idempotent due to creating a unique name via hash
    --- Inspiration reference http://xpertkb.com/compute-hash-string-powershell/

    User Experience
    - Added logic to return to initial subscription context after successfully running the script (useful on Tenant / Management Group analysis)
    - Improved token expiration experience for Azure Auth
    - Added Total Execution Time to help understand performance of script against environment
    - Updated Examples

    Visual Updates
    - Prettify function added to clean up JSON export
    -- Inspiration via reference article / source: https://stackoverflow.com/questions/24789365/prettify-json-in-powershell-3/61988399#61988399
    - Added process to clean up exported JSON 
    -- Credit to https://github.com/DeadPoolHeartsRR for their input on another script to use logic to use regex to clean up non printable chars (thank you! - Dead Pool Rocks BTW :) )

    Feature Enhancement
    - Added "Kind" to evaluation to support RPs that leverage kind in category evaluation (Example: Azure SQL DW vs Azure SQL DB)

   November 27, 2019 1.4
    - Updated RoleDefinitionID for Log Analytics based policies to be "Log Analytics Contributor"
    - Special thanks to Dimitri Lider, and Julian Hayward (Microsoft) for their input on this update! Keep the ideas coming! :)
    - Added Parameter Sets to initial parameters to refine experience

    - Added an option for Management Group as a scope providing a bit more flexiblity when it comes to scanning for resourceTypes supporting Diags.
    - Special thanks to Sam El-Anis (Microsoft) https://twitter.com/SamElAnis for the idea on this one!
   
   October 23, 2019 1.3
    - Added parameter for "all locations" for Log Analytics based policies
    - Special thanks to Dimitri Lider (Microsoft) for his input on this feature! Keep the ideas coming! :)
   
   August 21, 2019 1.2   
    - Improved efficiency for skipping invalid resources on analysis
    - Added Tenant to bypass subscription listing and go against all subs in current AD tenant
    - Added LogPolicyOnly switch to only export Azure Policies for resources that support Logs (metrics bypassed)
    - Special thanks to Dimitri Lider (Microsoft) for his contributions to the 2nd and 3rd bullet above
      Thank you for providing feedback Dimitri!
   
   June 06, 2019
   Updated a parameter for Event Hub name causing issues with configuration of Diagnostic Settings

   April 29, 2019 Initial
   Special thanks to John Kemnetz @jkemnetz (https://twitter.com/jkemnetz) for his initial project 
   here that I based some of my array logic off of: https://github.com/johnkemnetz/azmon-onboarding/tree/master/policies

   Thanks to Tao Yang @MrTaoYang (https://twitter.com/MrTaoYang) for his collaboration initially and his 
   hard work he has done here: https://blog.tyang.org/2018/11/19/configuring-azure-resources-diagnostic-log-settings-using-azure-policy/
   that he has created to support our community in this space!

   And thank you Nick Kiest from the Azure Monitor Product Team for supporting the project from their side seeing value in the effort!

   Finally Kristian Nese @KristianNese (https://twitter.com/KristianNese) from AzureCAT for his direct support on feedback as I navigated this effort and for him providing technical expertize in this space.

.LINK
    This script posted to and discussed at the following locations:
    https://aka.ms/AzPolicyScripts
#>

[cmdletbinding(
        DefaultParameterSetName='Default'
    )]

param
(
    # Environment defines what cloud you are analyzing (defaults to AzureCloud)
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Export')]
    [ValidateSet("AzureChinaCloud","AzureCloud","AzureGermanCloud","AzureUSGovernment")]
    [string]$Environment = "AzureCloud",    # Environment defines what cloud you are analyzing (defaults to AzureCloud)

    # Use this switch to enable the script to run via SPN in an Azure DevOps Pipeline
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Export')]
    [switch]$ADO = $False,

    # Default of $False assumes subscription as target - if $True will modify intiative properties to support MG target
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Export')]
    [switch]$ManagementGroupDeployment=$False,

    # Export Directory Path for Artifacts - if not set - will default to script directory
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Export')]
    [string]$ExportDir,

    # Export all policies without prompting - default is false
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ExportAll=$False,

    # Export Event Hub Specific Policies
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ExportEH=$False,

    # Export Log Analytics Specific Policies
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ExportLA=$False,

    # Export Storage Specific Policies
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ExportStorage=$False,

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(Mandatory=$False)]
    [Parameter(ParameterSetName='Subscription')]
    [string]$SubscriptionId,

    # Tenant switch to bypass subscriptionId requirement
    [Parameter(Mandatory=$False)]
    [Parameter(ParameterSetName='Tenant')]
    [switch]$Tenant=$False,

    # Management Group switch to allow for scanning all subs in a management group (instead of tenant wide or sub only)
    [Parameter(Mandatory=$False)]
    [Parameter(ParameterSetName='ManagementGroup')]
    [switch]$ManagementGroup=$False,

    # Management Group ID to scan (if left blank - will build list and prompt for selection if $ManagementGroup switch is used)
    [Parameter(Mandatory=$False)]
    [Parameter(ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupID,

    # Validate all exported policies to ensure they are proper JSON
    [Parameter(Mandatory=$False)]
    [switch]$ValidateJSON=$False,    

    # Switch to determine if you are going to export an ARM Initiative or all policy files.  Default is all policy files unless this switch is used
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Initiative')]
    [switch]$ExportInitiative=$False,

    # Specify a policy initiative display name (default will be used otherwise)
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Initiative')]
    [ValidateLength(1,127)]
    [string]$InitiativeDisplayName,

    # Specify your output file name for the ARM Template Policy Initiative.  If not used, ARM-Template-azurepolicyinit.json will be used
    [Parameter(ParameterSetName='Default',Mandatory = $False)]
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [Parameter(ParameterSetName='Initiative')]
    [string]$TemplateFileName,

    # When switch is used, only Azure Policies to capture logs will be exported (metric only resources bypassed)
    [switch]$LogPolicyOnly=$False,

    # AllRegions switch to allow log Analytics to use all regions instead of being region sensitive
    [switch]$AllRegions=$False,

    # Add ResourceType to reduce scope to Resource Type instead of entire list of resources to scan
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [string]$ResourceType,

    # Add a ResourceGroup name to reduce scope from entire Azure Subscription to RG
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [string]$ResourceGroupName,

    # Add a ResourceName name to reduce scope from entire Azure Subscription to specific named resource
    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Subscription')]
    [Parameter(ParameterSetName='Tenant')]
    [Parameter(ParameterSetName='ManagementGroup')]
    [string]$ResourceName
)

# FUNCTIONS
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

# Get the ResourceType listing from all ResourceTypes capable in this subscription
# to be sent to log analytics - use "-ResourceType" param to bypass
function Get-ResourceType (
    [Parameter(Mandatory=$True)]
    [array]$allResources,
    [Parameter(Mandatory=$False)]
    [array]$analysis

    )
{
    If(!($analysis))
    {
        $analysis = @()
    }
    
    $GetScanDetails = @{
        Headers = @{
            Authorization = "Bearer $($token.AccessToken)"
            'Content-Type' = 'application/json'
        }
        Method = 'Get'
        UseBasicParsing = $true
    }
    foreach($resource in $allResources)
    {
        $Invalid = $false
        $Categories =@();
        $metrics = $false #initialize metrics flag to $false
        $logs = $false #initialize logs flag to $false
        
        #Establish URI to gather resources
        # Determine cloud and ensure proper REST Endpoint defined
        $azEnvironment = Get-AzEnvironment -Name $Environment
        $URI = "$($azEnvironment.ResourceManagerUrl)$($Resource.ResourceId.substring(1))/providers/microsoft.insights/diagnosticSettingsCategories/?api-version=2017-05-01-preview" 
        #Write-Host "URI: $($URI)"
        
        $Exists = $false
        if($Analysis)
        {
            foreach($A in $Analysis)
            {
                if($($Resource.resourceType -eq $A.resourcetype) -and $($Resource.Kind -eq $A.Kind))
                {
                    $exists = $True                    
                }
            }
        }
        if (!($Exists))
        {
            try
            {
                Write-Verbose "Checking $($resource.ResourceType)"
                Try
                {
                    $Status = Invoke-WebRequest -uri $URI @GetScanDetails
                }
                catch
                {
                    # Uncomment below to see actual error.  Certain resources are not ResourceTypes that can support Logs and Metrics so the host error is being muted
                    #write-host $Error[0] -ForegroundColor Red
                    $Invalid = $True
                    $Logs = $False
                    $Metrics = $False
                    $ResponseJSON = ''
                }
                if(!($Invalid))
                {
                    $ResponseJSON = $Status.Content|ConvertFrom-Json -ErrorAction SilentlyContinue
                }
                
                # If logs are supported or metrics on each resource, set value as $True
                If($ResponseJSON)
                {                
                    foreach($R in $ResponseJSON.value)
                    {
                        if($R.properties.categoryType -eq "Metrics")
                        {
                            $metrics = $true
                        }
                        if($R.properties.categoryType -eq "Logs")
                        {
                            $Logs = $true
                            $Categories += $r.name
                        }
                    }
                    $Kind = $Resource.kind                    
                }
            }
            catch {}
            finally
            {
                $object = New-Object -TypeName PSObject -Property @{'ResourceType' = $resource.ResourceType; 'Metrics' = $metrics; 'Logs' = $logs; 'Categories' = $Categories; 'Kind' = $Kind}
                $analysis += $object
            }
        }
    }
    # Return the list of supported resources
    # Add the "ALL" option to the tail of the analysis array if we are only going against one subscription
    if($SubscriptionId)
    {
        $object = New-Object -TypeName PSObject -Property @{'ResourceType' = "All"; 'Metrics' = "True"; 'Logs' = "True"; 'Categories' = "Various"; 'Kind' = "Various"}
        $analysis += $object
    }
    $analysis
}

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

#Build the Log Array for each Resource Type
function New-LogArray
(
     [Parameter(Mandatory=$True)]
     [array]$logCategories
)
{
    $logsArray += '
                                                "logs": ['
        foreach ($element in $logCategories) {
            $logsArray += "
                                                    {
                                                        `"category`": `"$element`",
                                                        `"enabled`": `"[parameters('logsEnabled')]`"
                                                    },"
        }
        $logsArray = $logsArray.Substring(0,$logsArray.Length-1)
        $logsArray += '
                                                ]'
    $logsArray
}

# Build the metric array (if relevant for the resourceType and export)
function New-MetricArray
{
    $metricsArray = '
                                                "metrics": [
                                                    {
                                                        "category": "AllMetrics",
                                                        "enabled": "[parameters(''metricsEnabled'')]",
                                                        "retentionPolicy": {
                                                            "enabled": false,
                                                            "days": 0
                                                        }
                                                    }
                                                ]'
    $metricsArray
}

function Update-LogAnalyticsJSON
(
    [Parameter(Mandatory=$True)]
    [string]$resourceType,
    [Parameter(Mandatory=$False)]
    [string]$metricsArray,
    [Parameter(Mandatory=$False)]
    [string]$logsArray,
    [Parameter(Mandatory=$True)]
    [string]$nameField,
    [Parameter(Mandatory=$False)]
    [string]$ExportInitiative,
    [Parameter(Mandatory=$False)]
    [string]$JSONType,
    [Parameter(Mandatory=$False)]
    [string]$Kind,
    [Parameter(Mandatory=$False)]
    [string]$PolicyResourceDisplayName,
    [Parameter(Mandatory=$False)]
    [string]$PolicyName
)
{
if($Kind)
{
    $JSONKind = @'
    ,
                    {
                        "field":  "kind",
                        "equals":  "<RESOURCE KIND>"
                    }
'@
}
else
{
    $JSONKind = $Null
}

$JSONARRAY=@()
if($AllRegions)
{
    $JSONPARMS = @'
{
            "profileName": {
                "type": "String",
                "metadata": {
                    "displayName": "Profile Name for Config",
                    "description": "The profile name Azure Diagnostics"
                }
            },
            "logAnalytics": {
                "type": "string",
                "metadata": {
                    "displayName": "logAnalytics",
                    "description": "The target Log Analytics Workspace for Azure Diagnostics",
                    "strongType": "omsWorkspace"
                }
            },
            "metricsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Metrics",
                    "description": "Enable Metrics - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "False"
            },
            "logsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Logs",
                    "description": "Enable Logs - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "True"
            }
        }
'@

$JSONRULES = @'
{
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "<RESOURCE TYPE>"
                    }<RESOURCE KIND>
                ]
            },
            "then": {
                "effect": "deployIfNotExists",
                "details": {
                    "type": "Microsoft.Insights/diagnosticSettings",
                    "existenceCondition": {
                        "allOf": [
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
                                "equals": "[parameters('LogsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
                                "equals": "[parameters('MetricsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/workspaceId",
                                "equals": "[parameters('logAnalytics')]"
                            }
                        ]
                    },
                    "roleDefinitionIds": [
                        "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
                    ],
                    "deployment": {
                        "properties": {
                            "mode": "incremental",
                            "template": {
                                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                "contentVersion": "1.0.0.0",
                                "parameters": {
                                    "name": {
                                        "type": "string"
                                    },
                                    "logAnalytics": {
                                        "type": "string"
                                    },
                                    "metricsEnabled": {
                                        "type": "string"
                                    },
                                    "logsEnabled": {
                                        "type": "string"
                                    },
                                    "profileName": {
                                        "type": "string"
                                    }
                                },
                                "variables": {},
                                "resources": [
                                    {
                                        "type": "<RESOURCE TYPE>/providers/diagnosticSettings",
                                        "apiVersion": "2017-05-01-preview",
                                        "name": "[concat(parameters('name'), '/', 'Microsoft.Insights/', parameters('profileName'))]",                                        
                                        "dependsOn": [],
                                        "properties": {
                                            "workspaceId": "[parameters('logAnalytics')]",<METRICS ARRAY><LOGS ARRAY>                                        
                                        }
                                    }
                                ],
                                "outputs": {
                                    "policy": {
                                        "type": "string",
                                        "value": "[concat(parameters('logAnalytics'), 'configured for diagnostic logs for ', ': ', parameters('name'))]"
                                    }
                                }
                            },
                            "parameters": {
                                "logAnalytics": {
                                    "value": "[parameters('logAnalytics')]"
                                },
                                "name": {
                                    "value": "[field('<NAME OR FULLNAME>')]"
                                },
                                "metricsEnabled": {
                                    "value": "[parameters('metricsEnabled')]"
                                },
                                "logsEnabled": {
                                    "value": "[parameters('logsEnabled')]"
                                },
                                "profileName": {
                                    "value": "[parameters('profileName')]"
                                }
                            }
                        }
                    }
                }
            }
        }
'@
}
else 
{
$JSONPARMS = @'
{
            "profileName": {
                "type": "String",
                "metadata": {
                    "displayName": "Profile Name for Config",
                    "description": "The profile name Azure Diagnostics"
                }
            },
            "logAnalytics": {
                "type": "string",
                "metadata": {
                    "displayName": "logAnalytics",
                    "description": "The target Log Analytics Workspace for Azure Diagnostics",
                    "strongType": "omsWorkspace"
                }
            },
            "azureRegions": {
                "type": "Array",
                "metadata": {
                    "displayName": "Allowed Locations",
                    "description": "The list of locations that can be specified when deploying resources",
                    "strongType": "location"
                }
            },
            "metricsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Metrics",
                    "description": "Enable Metrics - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "False"
            },
            "logsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Logs",
                    "description": "Enable Logs - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "True"
            }
        }
'@

$JSONRULES = @'
{
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "<RESOURCE TYPE>"
                    },
                    {
                        "field": "location",
                        "in": "[parameters('AzureRegions')]"
                    }<RESOURCE KIND>
                ]
            },
            "then": {
                "effect": "deployIfNotExists",
                "details": {
                    "type": "Microsoft.Insights/diagnosticSettings",
                    "existenceCondition": {
                        "allOf": [
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
                                "equals": "[parameters('LogsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
                                "equals": "[parameters('MetricsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/workspaceId",
                                "equals": "[parameters('logAnalytics')]"
                            }
                        ]
                    },
                    "roleDefinitionIds": [
                        "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
                    ],
                    "deployment": {
                        "properties": {
                            "mode": "incremental",
                            "template": {
                                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                "contentVersion": "1.0.0.0",
                                "parameters": {
                                    "name": {
                                        "type": "string"
                                    },
                                    "location": {
                                        "type": "string"
                                    },
                                    "logAnalytics": {
                                        "type": "string"
                                    },
                                    "metricsEnabled": {
                                        "type": "string"
                                    },
                                    "logsEnabled": {
                                        "type": "string"
                                    },
                                    "profileName": {
                                        "type": "string"
                                    }
                                },
                                "variables": {},
                                "resources": [
                                    {
                                        "type": "<RESOURCE TYPE>/providers/diagnosticSettings",
                                        "apiVersion": "2017-05-01-preview",
                                        "name": "[concat(parameters('name'), '/', 'Microsoft.Insights/', parameters('profileName'))]",
                                        "location": "[parameters('location')]",
                                        "dependsOn": [],
                                        "properties": {
                                            "workspaceId": "[parameters('logAnalytics')]",<METRICS ARRAY><LOGS ARRAY>                                        
                                        }
                                    }
                                ],
                                "outputs": {
                                    "policy": {
                                        "type": "string",
                                        "value": "[concat(parameters('logAnalytics'), 'configured for diagnostic logs for ', ': ', parameters('name'))]"
                                    }
                                }
                            },
                            "parameters": {
                                "logAnalytics": {
                                    "value": "[parameters('logAnalytics')]"
                                },
                                "location": {
                                    "value": "[field('location')]"
                                },
                                "name": {
                                    "value": "[field('<NAME OR FULLNAME>')]"
                                },
                                "metricsEnabled": {
                                    "value": "[parameters('metricsEnabled')]"
                                },
                                "logsEnabled": {
                                    "value": "[parameters('logsEnabled')]"
                                },
                                "profileName": {
                                    "value": "[parameters('profileName')]"
                                }
                            }
                        }
                    }
                }
            }
        }
'@
}
if(!($ExportInitiative))
{
    $JSONVar = @'
{

'@
}
$JSONVar = $JSONVar + $JSONType + @'
    "properties": {
        "displayName": "<POLICY RESOURCE DISPLAY NAME>",
        "mode": "Indexed",
        "description": "This policy automatically deploys diagnostic settings to <POLICYDISPLAYNAME>.",
        "metadata": {
            "category": "Monitoring"
        },
        "parameters": <INSERT Parameters>,
        "policyRule": <INSERT Policy Rules>
    }
}
'@
    # Update Content according to type, categories, fullname or name
    $JSONVar = $JSONVar.replace('<POLICY RESOURCE DISPLAY NAME>', $PolicyResourceDisplayName)
    $JSONVar = $JSONVar.replace('<POLICYDISPLAYNAME>', $PolicyResourceDisplayName)

    # Output content for Azure Rules file
    $JSONRules = $JSONRules.replace('<RESOURCE TYPE>', $ResourceType)
    $JSONRules = $JSONRules.replace('<METRICS ARRAY>', $metricsArray)
    $JSONRules = $JSONRules.replace('<LOGS ARRAY>', $logsArray)
    $JSONRules = $JSONRules.replace('<NAME OR FULLNAME>', $nameField)
    $JSONRULES = $JSONRules.Replace('<RESOURCE KIND>', $JSONKind)
    $JSONRULES = $JSONRules.Replace('<RESOURCE KIND>', $Kind)

    # Merge components to build azurepolicy output content
    $AzurePolicyJSON = $JSONVar
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Parameters>', $JSONPARMS)
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Policy Rules>',$JSONRULES)

    # Let's do some additional work if this is a policy initiative we are working on
    If($ExportInitiative)
    {
        # Retrieve parameters from Rules JSON for processing in initiative
        $RuleParams = $JSONRules | ConvertFrom-Json 
        # Unescape non printable chars from string / JSON payload
        $RuleParams = $RuleParams.then.details.deployment.properties.parameters
        $RuleParams = $RuleParams |convertto-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        
        # Now add additional brackets to ensure ARM template doesn't get confused
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[field', ': "' + '[[field')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[last', ': "' + '[[last')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[parameters', ': "' + '[[parameters')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[name', ': "' + '[[name')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[concat', ': "' + '[[concat')
        
        # Clean up Init params variable
        $RuleParams = $RuleParams.Replace('"[field', '"[[field')
        $RuleParams = $RuleParams.Replace('"[last', '"[[last')
        $RuleParams = $RuleParams.Replace('"[parameters', '"[[parameters')
        $RuleParams = $RuleParams.Replace('"[name', '"[[name')
        $RuleParams = $RuleParams.Replace('"[concat', '"[[concat')
    }
    If(!($AllRegions))
    {
        $locationParm = @'
    
    "azureRegions": {
        "value": "[[parameters('azureRegions')]"
    },
'@
    }
    else {
        $locationParm = $Null
    }
    
    $initParams = @'
    "parameters": {
        "logAnalytics": {
            "value": "[[parameters('logAnalytics')]"
        },<LOCATION PARAM>
        "metricsEnabled": {
            "value": "[[parameters('metricsEnabled')]"
        },
        "logsEnabled": {
            "value": "[[parameters('logsEnabled')]"
        },
        "profileName": {
            "value": "[[parameters('profileName')]"
        }
    }
'@
    
    $initParams = $initParams.Replace("<LOCATION PARAM>", $locationParm)

    # Build the separate JSON payloads into an array
    $JSONARRAY += $JSONPARMS
    $JSONARRAY += $JSONRULES
    $JSONARRAY += $AzurePolicyJSON
    $JSONARRAY += $initParams
    
    # Send the payload
    $JSONARRAY    
}
function Update-EventHubJSON
(
    [Parameter(Mandatory=$True)]
    [string]$resourceType,
    [Parameter(Mandatory=$False)]
    [string]$metricsArray,
    [Parameter(Mandatory=$False)]
    [string]$logsArray,
    [Parameter(Mandatory=$True)]
    [string]$nameField,
    [Parameter(Mandatory=$False)]
    [string]$ExportInitiative,
    [Parameter(Mandatory=$False)]
    [string]$JSONType,
    [Parameter(Mandatory=$False)]
    [string]$Kind,
    [Parameter(Mandatory=$False)]
    [string]$PolicyResourceDisplayName,
    [Parameter(Mandatory=$False)]
    [string]$PolicyName
)
{
    if($Kind)
    {
        $JSONKind = @'
        ,
                        {
                            "field":  "kind",
                            "equals":  "<RESOURCE KIND>"
                        }
'@
    }
    else
    {
        $JSONKind = $Null
    }    
    
    
    $JSONARRAY=@()

$JSONPARMS = @'
{
            "profileName": {
                "type": "String",
                "metadata": {
                    "displayName": "Profile Name for Config",
                    "description": "The profile name Azure Diagnostics"
                }
            },
            "eventHubName": {
                "type": "String",
                "metadata": {
                    "displayName": "EventHub Name",
                    "description": "The event hub for Azure Diagnostics",
                    "strongType": "Microsoft.EventHub/Namespaces/EventHubs",
                    "assignPermissions": true
                }
            },
            "eventHubRuleId": {
                "type": "String",
                "metadata": {
                    "displayName": "EventHubRuleID",
                    "description": "The event hub RuleID for Azure Diagnostics",
                    "strongType": "Microsoft.EventHub/Namespaces/AuthorizationRules",
                    "assignPermissions": true
                }
            },
            "azureRegions": {
                "type": "Array",
                "metadata": {
                    "displayName": "Allowed Locations",
                    "description": "The list of locations that can be specified when deploying resources",
                    "strongType": "location"
                }
            },
            "metricsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Metrics",
                    "description": "Enable Metrics - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "False"
            },
            "logsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Logs",
                    "description": "Enable Logs - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "True"
            }
        }
'@

If(!($AllRegions))
{
    $locationParm = @'

"azureRegions": {
    "value": "[[parameters('azureRegions')]"
},
'@
}
else {
    $locationParm = $Null
}

$initParams = @'
"parameters": {
    "eventHubName": {
        "value": "[[parameters('eventHubName')]"
    },
    "eventHubRuleId": {
        "value": "[[parameters('eventHubRuleId')]"
    },
    "azureRegions": {
        "value": "[[parameters('azureRegions')]"
    },
    "metricsEnabled": {
        "value": "[[parameters('metricsEnabled')]"
    },
    "logsEnabled": {
        "value": "[[parameters('logsEnabled')]"
    },
    "profileName": {
        "value": "[[parameters('profileName')]"
    }
}
'@

$JSONRULES = @'
{
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "<RESOURCE TYPE>"
                    },
                    {
                        "field": "location",
                        "in": "[parameters('azureRegions')]"
                    }<RESOURCE KIND>
                ]
            },
            "then": {
                "effect": "deployIfNotExists",
                "details": {
                    "type": "Microsoft.Insights/diagnosticSettings",
                    "existenceCondition": {
                        "allOf": [
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
                                "equals": "[parameters('logsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
                                "equals": "[parameters('metricsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/eventHubName",
                                "equals": "[last(split(parameters('eventHubName'), '/'))]"
                            }
                        ]
                    },
                    "roleDefinitionIds": [
                        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
                    ],
                    "deployment": {
                        "properties": {
                            "mode": "incremental",
                            "template": {
                                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                "contentVersion": "1.0.0.0",
                                "parameters": {
                                    "name": {
                                        "type": "string"
                                    },
                                    "location": {
                                        "type": "string"
                                    },
                                    "eventHubName": {
                                        "type": "string"
                                    },
                                    "eventHubRuleId": {
                                        "type": "string"
                                    },
                                    "metricsEnabled": {
                                        "type": "string"
                                    },
                                    "logsEnabled": {
                                        "type": "string"
                                    },
                                    "profileName": {
                                        "type": "string"
                                    }
                                },
                                "variables": {},
                                "resources": [
                                    {
                                        "type": "<RESOURCE TYPE>/providers/diagnosticSettings",
                                        "apiVersion": "2017-05-01-preview",
                                        "name": "[concat(parameters('name'), '/', 'Microsoft.Insights/', parameters('profileName'))]",
                                        "location": "[parameters('location')]",
                                        "dependsOn": [],
                                        "properties": {
                                            "eventHubName": "[last(split(parameters('eventHubName'), '/'))]",
                                            "eventHubAuthorizationRuleId": "[parameters('eventHubRuleId')]",<METRICS ARRAY><LOGS ARRAY>
                                        }
                                    }
                                ],
                                "outputs": {
                                    "policy": {
                                        "type": "string",
                                        "value": "[concat(parameters('eventHubName'), 'configured for diagnostic logs for ', ': ', parameters('name'))]"
                                    }
                                }
                            },
                            "parameters": {
                                "eventHubName": {
                                    "value": "[parameters('eventHubName')]"
                                },
                                "location": {
                                    "value": "[field('location')]"
                                },
                                "name": {
                                    "value": "[field('<NAME OR FULLNAME>')]"
                                },
                                "eventHubRuleId": {
                                    "value": "[parameters('eventHubRuleId')]"
                                },
                                "metricsEnabled": {
                                    "value": "[parameters('metricsEnabled')]"
                                },
                                "logsEnabled": {
                                    "value": "[parameters('logsEnabled')]"
                                },
                                "profileName": {
                                    "value": "[parameters('profileName')]"
                                }
                            }
                        }
                    }
                }
            }
        }
'@
if(!($ExportInitiative))
{
    $JSONVar = @'
{

'@
}
$JSONVar = $JSONVar + $JSONType + @'
    "properties": {
        "displayName": "<POLICY RESOURCE DISPLAY NAME>",
        "mode": "Indexed",
        "description": "This policy automatically deploys diagnostic settings to <POLICYDISPLAYNAME>.",
        "metadata": {
            "category": "Monitoring"
        },
        "parameters": <INSERT Parameters>,
        "policyRule": <INSERT Policy Rules>
    }
}
'@    

    # Update Content according to type, categories, fullname or name
    $JSONVar = $JSONVar.replace('<POLICY RESOURCE DISPLAY NAME>', $PolicyResourceDisplayName)
    $JSONVar = $JSONVar.replace('<POLICYDISPLAYNAME>', $PolicyResourceDisplayName)

    # Output content for Azure Rules file
    $JSONRules = $JSONRules.replace('<RESOURCE TYPE>', $ResourceType)
    $JSONRULES = $JSONRULES.replace('<METRICS ARRAY>', $metricsArray)
    $JSONRULES = $JSONRULES.replace('<LOGS ARRAY>', $logsArray)
    $JSONRULES = $JSONRules.replace('<NAME OR FULLNAME>', $nameField)
    $JSONRULES = $JSONRULES.Replace('<RESOURCE KIND>', $JSONKind)
    $JSONRULES = $JSONRULES.Replace('<RESOURCE KIND>', $Kind)

    # Merge components to build azurepolicy output content
    $AzurePolicyJSON = $JSONVar
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Parameters>', $JSONPARMS)
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Policy Rules>',$JSONRULES)

    # Let's do some additional work if this is a policy initiative we are working on
    If($ExportInitiative)
    {
        # Retrieve parameters from Rules JSON for processing in initiative
        $RuleParams = $JSONRules | ConvertFrom-Json 
        # Unescape non printable chars from string / JSON payload
        $RuleParams = $RuleParams.then.details.deployment.properties.parameters
        $RuleParams = $RuleParams |convertto-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        
        # Now add additional brackets to ensure ARM template doesn't get confused
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[field', ': "' + '[[field')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[last', ': "' + '[[last')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[parameters', ': "' + '[[parameters')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[name', ': "' + '[[name')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[concat', ': "' + '[[concat')
        
        # Clean up Init params variable
        $RuleParams = $RuleParams.Replace('"[field', '"[[field')
        $RuleParams = $RuleParams.Replace('"[last', '"[[last')
        $RuleParams = $RuleParams.Replace('"[parameters', '"[[parameters')
        $RuleParams = $RuleParams.Replace('"[name', '"[[name')
        $RuleParams = $RuleParams.Replace('"[concat', '"[[concat')
    }

    # Build the separate JSON payloads into an array
    $JSONARRAY += $JSONPARMS
    $JSONARRAY += $JSONRULES
    $JSONARRAY += $AzurePolicyJSON
    $JSONARRAY += $initParams

    # Send the payload
    $JSONARRAY    
}

function Update-StorageJSON
(
    [Parameter(Mandatory=$True)]
    [string]$resourceType,
    [Parameter(Mandatory=$False)]
    [string]$metricsArray,
    [Parameter(Mandatory=$False)]
    [string]$logsArray,
    [Parameter(Mandatory=$True)]
    [string]$nameField,
    [Parameter(Mandatory=$False)]
    [string]$ExportInitiative,
    [Parameter(Mandatory=$False)]
    [string]$JSONType,
    [Parameter(Mandatory=$False)]
    [string]$Kind,
    [Parameter(Mandatory=$False)]
    [string]$PolicyResourceDisplayName,
    [Parameter(Mandatory=$False)]
    [string]$PolicyName
)
{
    if($Kind)
    {
        $JSONKind = @'
        ,
                        {
                            "field":  "kind",
                            "equals":  "<RESOURCE KIND>"
                        }
'@
    }
    else
    {
        $JSONKind = $Null
    }    
    
    
    $JSONARRAY=@()

$JSONPARMS = @'
{
            "profileName": {
                "type": "String",
                "metadata": {
                    "displayName": "Profile Name for Config",
                    "description": "The profile name Azure Diagnostics"
                }
            },
            "StorageAccountID": {
                "type": "String",
                "metadata": {
                    "displayName": "StorageAccountID",
                    "description": "The Storage Account ID for for Azure Diagnostics",
                    "strongType": "Microsoft.Storage/StorageAccounts",
                    "assignPermissions": true
                }
            },
            "azureRegions": {
                "type": "Array",
                "metadata": {
                    "displayName": "Allowed Locations",
                    "description": "The list of locations that can be specified when deploying resources",
                    "strongType": "location"
                }
            },
            "metricsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Metrics",
                    "description": "Enable Metrics - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "False"
            },
            "logsEnabled": {
                "type": "String",
                "metadata": {
                    "displayName": "Enable Logs",
                    "description": "Enable Logs - True or False"
                },
                "allowedValues": [
                    "True",
                    "False"
                ],
                "defaultValue": "True"
            }
        }
'@

If(!($AllRegions))
{
    $locationParm = @'

"azureRegions": {
    "value": "[[parameters('azureRegions')]"
},
'@
}
else {
    $locationParm = $Null
}

$initParams = @'
"parameters": {
    "storageAccountId": {
        "value": "[[parameters('storageAccountId')]"
    },
    "azureRegions": {
        "value": "[[parameters('azureRegions')]"
    },
    "metricsEnabled": {
        "value": "[[parameters('metricsEnabled')]"
    },
    "logsEnabled": {
        "value": "[[parameters('logsEnabled')]"
    },
    "profileName": {
        "value": "[[parameters('profileName')]"
    }
}
'@

$JSONRULES = @'
{
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "<RESOURCE TYPE>"
                    },
                    {
                        "field": "location",
                        "in": "[parameters('azureRegions')]"
                    }<RESOURCE KIND>
                ]
            },
            "then": {
                "effect": "deployIfNotExists",
                "details": {
                    "type": "Microsoft.Insights/diagnosticSettings",
                    "existenceCondition": {
                        "allOf": [
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
                                "equals": "[parameters('logsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
                                "equals": "[parameters('metricsEnabled')]"
                            },
                            {
                                "field": "Microsoft.Insights/diagnosticSettings/storageAccountId",
                                "equals": "[last(split(parameters('storageAccountId'), '/'))]"
                            }
                        ]
                    },
                    "roleDefinitionIds": [
                        "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
                    ],
                    "deployment": {
                        "properties": {
                            "mode": "incremental",
                            "template": {
                                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                                "contentVersion": "1.0.0.0",
                                "parameters": {
                                    "name": {
                                        "type": "string"
                                    },
                                    "location": {
                                        "type": "string"
                                    },
                                    "storageAccountId": {
                                        "type": "string"
                                    },
                                    "metricsEnabled": {
                                        "type": "string"
                                    },
                                    "logsEnabled": {
                                        "type": "string"
                                    },
                                    "profileName": {
                                        "type": "string"
                                    }
                                },
                                "variables": {},
                                "resources": [
                                    {
                                        "type": "<RESOURCE TYPE>/providers/diagnosticSettings",
                                        "apiVersion": "2017-05-01-preview",
                                        "name": "[concat(parameters('name'), '/', 'Microsoft.Insights/', parameters('profileName'))]",
                                        "location": "[parameters('location')]",
                                        "dependsOn": [],
                                        "properties": {
                                            "storageAccountId": "[parameters('storageAccountId')]",<METRICS ARRAY><LOGS ARRAY>
                                        }
                                    }
                                ],
                                "outputs": {
                                    "policy": {
                                        "type": "string",
                                        "value": "[concat(parameters('storageAccountId'), 'configured for diagnostic logs for ', ': ', parameters('name'))]"
                                    }
                                }
                            },
                            "parameters": {
                                "location": {
                                    "value": "[field('location')]"
                                },
                                "name": {
                                    "value": "[field('<NAME OR FULLNAME>')]"
                                },
                                "storageAccountId": {
                                    "value": "[parameters('storageAccountId')]"
                                },
                                "metricsEnabled": {
                                    "value": "[parameters('metricsEnabled')]"
                                },
                                "logsEnabled": {
                                    "value": "[parameters('logsEnabled')]"
                                },
                                "profileName": {
                                    "value": "[parameters('profileName')]"
                                }
                            }
                        }
                    }
                }
            }
        }
'@
if(!($ExportInitiative))
{
    $JSONVar = @'
{

'@
}
$JSONVar = $JSONVar + $JSONType + @'
    "properties": {
        "displayName": "<POLICY RESOURCE DISPLAY NAME>",
        "mode": "Indexed",
        "description": "This policy automatically deploys diagnostic settings to <POLICYDISPLAYNAME>.",
        "metadata": {
            "category": "Monitoring"
        },
        "parameters": <INSERT Parameters>,
        "policyRule": <INSERT Policy Rules>
    }
}
'@    

    # Update Content according to type, categories, fullname or name
    $JSONVar = $JSONVar.replace('<POLICY RESOURCE DISPLAY NAME>', $PolicyResourceDisplayName)
    $JSONVar = $JSONVar.replace('<POLICYDISPLAYNAME>', $PolicyResourceDisplayName)

    # Output content for Azure Rules file
    $JSONRules = $JSONRules.replace('<RESOURCE TYPE>', $ResourceType)
    $JSONRULES = $JSONRULES.replace('<METRICS ARRAY>', $metricsArray)
    $JSONRULES = $JSONRULES.replace('<LOGS ARRAY>', $logsArray)
    $JSONRULES = $JSONRules.replace('<NAME OR FULLNAME>', $nameField)
    $JSONRULES = $JSONRULES.Replace('<RESOURCE KIND>', $JSONKind)
    $JSONRULES = $JSONRULES.Replace('<RESOURCE KIND>', $Kind)

    # Merge components to build azurepolicy output content
    $AzurePolicyJSON = $JSONVar
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Parameters>', $JSONPARMS)
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Policy Rules>',$JSONRULES)

    # Let's do some additional work if this is a policy initiative we are working on
    If($ExportInitiative)
    {
        # Retrieve parameters from Rules JSON for processing in initiative
        $RuleParams = $JSONRules | ConvertFrom-Json 
        # Unescape non printable chars from string / JSON payload
        $RuleParams = $RuleParams.then.details.deployment.properties.parameters
        $RuleParams = $RuleParams |convertto-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        
        # Now add additional brackets to ensure ARM template doesn't get confused
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[field', ': "' + '[[field')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[last', ': "' + '[[last')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[parameters', ': "' + '[[parameters')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[name', ': "' + '[[name')
        $AzurePolicyJSON = $AzurePolicyJSON.Replace(': "[concat', ': "' + '[[concat')
        
        # Clean up Init params variable
        $RuleParams = $RuleParams.Replace('"[field', '"[[field')
        $RuleParams = $RuleParams.Replace('"[last', '"[[last')
        $RuleParams = $RuleParams.Replace('"[parameters', '"[[parameters')
        $RuleParams = $RuleParams.Replace('"[name', '"[[name')
        $RuleParams = $RuleParams.Replace('"[concat', '"[[concat')
    }

    # Build the separate JSON payloads into an array
    $JSONARRAY += $JSONPARMS
    $JSONARRAY += $JSONRULES
    $JSONARRAY += $AzurePolicyJSON
    $JSONARRAY += $initParams

    # Send the payload
    $JSONARRAY    
}

# Build File Name / paths for Azure Policy Exports
function Parse-ResourceType
(
    [Parameter(Mandatory=$True)]
    [string]$resourceType,
    [Parameter(Mandatory=$True)]
    [string]$sinkDest,
    [Parameter(Mandatory=$False)]
    [string]$kind
    

)
{
    $KindDirVar = $null
    if($Kind)
    {
        $pattern = '[^a-zA-Z0-9.-]'
        $KindDirVar = $Kind -replace $pattern, '-'
        $KindDirVar = "-" + $KindDirVar
    }
    $ReturnVar=@()
    if($ResourceType.Split("/").count -eq 3)
    {
        $nameField = "fullName"
        $DirectoryNameBase = "Apply-Diag-Settings-$sinkDest-" + $($resourceType.Split("/", 3))[0] + "-" + $($resourceType.Split("/", 3))[1] + "-" + $($resourceType.Split("/", 3))[2] + $KindDirVar
    }
    if($ResourceType.Split("/").count -eq 2)
    {
        $nameField = "name"
        $DirectoryNameBase = "Apply-Diag-Settings-$sinkDest-" + $($resourceType.Split("/", 2))[0] + "-" + $($resourceType.Split("/", 2))[1] + $KindDirVar
    }
    $ReturnVar += $DirectoryNameBase
    $ReturnVar += $nameField
    $ReturnVar
}

# Validate our JSON file is proper in syntax / format and can be leveraged
Function Validate-JSON
(
    [Parameter(Mandatory=$True)]
    [string]$ExportDir
)
{
    $filesToValidate = Get-ChildItem $ExportDir\*.json -rec
    $ValidCheck = @()
    foreach($File in $filesToValidate)
    {
        try 
        {
            $null = Get-Content -Path $($File.pspath)|ConvertFrom-Json -ErrorAction stop;
            $ValidCheck += "VALID: " + "$($File.FullName)"            
            
        } 
        catch
        {
            $ValidCheck += "INVALID: " + "$($File.FullName)"            
        }

    }
    $ValidCheck
}

function New-PolicyInitiative
(
    [Parameter(Mandatory=$True)]
    [string]$PolicyBag,
    [Parameter(Mandatory=$True)]
    [string]$PolicyRSIDs,
    [Parameter(Mandatory=$True)]
    [string]$PolicyDefParams,
    [Parameter(Mandatory=$True)]
    [string]$Parameters,
    [Parameter(Mandatory=$True)]
    [string]$sinkDest,
    [Parameter(Mandatory=$True)]
    [string]$InitiativeDisplayName,
    [Parameter(Mandatory=$True)]
    [string]$InitiativeName,
    [Parameter(Mandatory=$True)]
    [boolean]$ManagementGroupDeployment
)
{
    # Scrub trailing commas
    $PolicyRSIDs = $PolicyRSIDs.substring(0,$PolicyRSIDs.length -3)
    $PolicyDefParams = $PolicyDefParams.substring(0,$PolicyDefParams.length -3)
    
    # Adding support for Management Group deployment scope.  If parameter switch is used for -ManagementGroupDeployment, we'll put the right JSON in to support
    if($ManagementGroupDeployment -eq $true)
    {
        $MGJSONParam = @'
{
    "TargetMGID": {
        "type": "string",
        "defaultValue": ""
    }
}
'@
        $schema = "https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#"
    }
    else
    {
        $MGJSONParam = '{}'
        $schema = "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
    }
    # Build Template reference for Policy Initiative
    $InitiativeTemplate = @'
{
    "$schema": "<SUB OR MG SCHEMA>",
    "contentVersion": "1.0.0.0",
    "parameters": <ManagementGroupID>,
    "resources": [
        <AzurePolicyPropertyBag>
        {
            "type": "Microsoft.Authorization/policySetDefinitions",
            "apiVersion": "2019-09-01",
            "name": "<AZURE DIAG INITIATIVE NAME>",
            "dependsOn": [
<Policy INIT RESIDs>
            ],
            "properties": {
                "displayName": "<AZURE DIAG INITIATIVE DISPLAY NAME>",
                "description": "This initiative configures application Azure resources to forward diagnostic logs and metrics to an Azure Diagnostics sink point.",
                "metadata": {
                    "category": "Monitoring"
                },
                "parameters": <ParametersGoHere>,
                "policyDefinitions": [
                    <PolicyDefParams>
                ]
            }
        }
    ]
}
'@
    # Update Policy Initiative reference strings according to what we've discovered
    $InitiativeTemplate = $InitiativeTemplate.Replace("<AZURE DIAG INITIATIVE NAME>", $InitiativeName)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<AZURE DIAG INITIATIVE DISPLAY NAME>", $InitiativeDisplayName)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<AzurePolicyPropertyBag>", $PolicyBag)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<Policy INIT RESIDs>", $PolicyRSIDs)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<ParametersGoHere>", $Parameters)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<PolicyDefParams>", $PolicyDefParams)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<ManagementGroupID>", $MGJSONParam)
    $InitiativeTemplate = $InitiativeTemplate.Replace("<SUB OR MG SCHEMA>", $schema)

    $InitiativeTemplate
}

# Prettify Function for JSON 
# Reference article / source: https://stackoverflow.com/questions/24789365/prettify-json-in-powershell-3/61988399#61988399
# Also credit to https://github.com/DeadPoolHeartsRR for their input on another script to use logic to use regex to clean up non printable chars
function Format-JSON ($JSON)
{
    $PrettifiedJSON = ($JSON) | convertfrom-json | convertto-json -depth 50 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
    $PrettifiedJSON
}

# This function converts a string (name of a policy) into a hash equivelent for fitting into the max lenghth of policy object (64 chars)
# http://xpertkb.com/compute-hash-string-powershell/
Function Create-Hash ($StringToHash)
{
    $hasher = new-object System.Security.Cryptography.MD5CryptoServiceProvider
    $toHash = [System.Text.Encoding]::UTF8.GetBytes($StringToHash)
    $hashByteArray = $hasher.ComputeHash($toHash)
    foreach($byte in $hashByteArray)
    {
      $result += "{0:X2}" -f $byte
    }
    return $result;
 }

# MAIN SCRIPT
$Start = $(Get-date)
If($LogsExport)
{
    Write-host "You've opted to export policies for resources that only have logs supported .." -ForegroundColor Yellow
}
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
# Determine where the script is running - build export dir
IF(!$($ExportEH) -and !($ExportLA) -and !($ExportStorage) -and !($ValidateJSON))
{
    write-host "Nothing to do - please use either parameter -ExportLA, -ExportEH, -ExportStorage, -ValidateJSON (or all four) to export / validate policies" -ForegroundColor Yellow
    Set-Location $CurrentDir
    exit
}

# An initiative cannot support multiple sink points due to variance in parameters for each type of policy
if($ExportInitiative -and (($($ExportEH.IsPresent) + $($ExportLA.IsPresent) + $($ExportStorage.IsPresent)) -gt 1))
{
    Write-host "Initiative Export option does not support more than one sink point for Policies together.  Please choose parameter -ExportLA, -ExportStorage, or -ExportEH only when using -ExportInitiative" -ForegroundColor Yellow
    break
}

If(!($ExportDir))
{
    $ExportDir = $CurrentDir
}

#Variable Definitions
[array]$Resources = @()
$SubScriptionsToProcess = $null

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

# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
If($AzureLogin -and !($SubscriptionID) -and !($Tenant) -and !($ManagementGroup))
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
if($SubscriptionId -and !($Tenant) -and !($ManagementGroup))
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
if($Tenant)
{
    $SubScriptionsToProcess = Get-AzSubscription -TenantId $($token).TenantId
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
        # Determine cloud and ensure proper REST Endpoint defined
        $azEnvironment = Get-AzEnvironment -Name $Environment
        $GetBody = BuildBody -method "GET"
        $MGSubsDetailsURI = "$($azEnvironment.ResourceManagerUrl)/providers/microsoft.management/managementGroups/$($ManagementGroupID)/descendants?api-version=2018-03-01-preview"
        $GetResults = (Invoke-RestMethod -uri $MGSubsDetailsURI @GetBody).value
        foreach($Result in $GetResults| Where-Object {$_.type -eq "/subscriptions"})
        {
            $SubScriptionsToProcess += $Result 
        }
    }
    else {
        Write-Host "No ManagementGroupID found - ERROR!"
    }
    
}

# Determine which resourcetype to search on
[array]$ResourcesToCheck = @()
[array]$DiagnosticCapable=@()
[array]$Logcategories = @()

IF($($ExportEH) -or ($ExportLA) -or ($ExportStorage))
{
    # Build parameter set according to parameters provided.
    $FindResourceParams = @{}
    if($ResourceType)
    {
        $FindResourceParams['ResourceType'] = $ResourceType
    }
    if($ResourceGroupName)
    {
        $FindResourceParams['ResourceGroupName'] = $ResourceGroupName
    }
    if($ResourceName)
    {
        $FindResourceParams['Name'] = $ResourceName
    }
    if($SubscriptionId)
    {
        $ResourcesToCheck = Get-AzResource @FindResourceParams 
    }

    # If resourceType defined, ensure it can support diagnostics configuration
    if($ResourceType)
    {
        try
        {
            $Resources = $ResourcesToCheck
            $DiagnosticCapable = Get-ResourceType -allResources $Resources
            [int]$ResourceTypeToProcess = 0
            if ( $DiagnosticCapable.Count -eq 2)
            {
                $ResourceTypeToProcess = 1
            }
        }
        catch
        {
            Throw write-host "No diagnostic capable resources of type $ResourceType available in selected subscription $SubscriptionID" -ForegroundColor Red
        }

    }

    # Gather a list of resources supporting Azure Diagnostic logs and metrics and display a table
    if(!($ResourceType))
    {
        try
        {
            if($SubscriptionId -and !($Tenant))
            {
                Write-Host "Gathering a list of monitorable Resource Types from Azure Subscription " -NoNewline -ForegroundColor Cyan
                Write-Host "$($SubscriptionToUse.Subscription.Name)..." -ForegroundColor Yellow
                
                # If we only want log policies - only export those otherwise export all
                If(!($LogPolicyOnly))
                {
                    $DiagnosticCapable = Add-IndexNumberToArray (Get-ResourceType -allResources $ResourcesToCheck).where({$_.metrics -eq $True -or $_.Logs -eq $True}) 
                }
                else
                {
                    $DiagnosticCapable = Add-IndexNumberToArray (Get-ResourceType -allResources $ResourcesToCheck).where({$_.Logs -eq $True}) 
                }
            }
            elseif($Tenant -or ($ManagementGroup -and $ManagementGroupID))
            {
                if($Tenant){Write-Host "Gathering a list of monitorable Resource Types from Azure AD Tenant " -ForegroundColor Cyan}
                if($ManagementGroup){Write-Host "Gathering a list of monitorable Resource Types from Management Group $($ManagementGroupID) " -ForegroundColor Cyan}
                Write-Host "A total of $($SubScriptionsToProcess.count) subscriptions to process..."
                foreach($Sub in $SubScriptionsToProcess)
                {
                    if($Tenant)
                    {
                        $SubIDToProcess = $($Sub.SubscriptionId)
                        $SubName = $($Sub.Name)
                    }
                    if($ManagementGroup)
                    {
                        $SubIDToProcess = $Sub.Name 
                        $SubName = $Sub.properties.displayName
                    }
                    $SelectedSub = Select-AzSubscription -SubscriptionID $SubIDToProcess
                    Write-Host "Analyzing Subscription: $SubName"
                    $ResourcesToCheck = Get-AzResource
                    if($ResourcesToCheck)
                    {                    
                        if(!($DiagCapable))
                        {
                            $DiagCapable = Get-ResourceType -allResources $ResourcesToCheck
                        }
                        else {
                            $DiagCapable = Get-ResourceType -allResources $ResourcesToCheck -analysis $DiagCapable
                        }
                    }
                }
                # Add the "ALL" option after grabbing all resourceTypes from all subs in Tenant
                $object = New-Object -TypeName PSObject -Property @{'ResourceType' = "All"; 'Metrics' = "True"; 'Logs' = "True"; 'Categories' = "Various";'Kind' = "Various"}
                $DiagCapable += $object
                
                # If we only want log policies - only export those otherwise export all
                If(!($LogPolicyOnly))
                {
                    $DiagnosticCapable = Add-IndexNumberToArray ($DiagCapable).where({$_.metrics -eq $True -or $_.Logs -eq $True}) 
                }
                else
                {
                    $DiagnosticCapable = Add-IndexNumberToArray ($DiagCapable).where({$_.Logs -eq $True}) 
                }
                
            }

            [int]$ResourceTypeToProcess = 0
            if($($DiagnosticCapable|Where-Object {$_.ResourceType -ne "ALL"}).count -eq 1)
            {
                $ResourceTypeToProcess = 1
            }
            while($ResourceTypeToProcess -gt $DiagnosticCapable.Count -or $ResourceTypeToProcess -lt 1 -and $ExportALL -ne $True)
            {
                Write-Host "The table below are the resource types that support sending diagnostics to Log Analytics and Event Hubs"
                $DiagnosticCapable | Select-Object "#", ResourceType, Metrics, Logs |Format-Table
                try
                {
                    $ResourceTypeToProcess = Read-Host "Please select a number from 1 - $($DiagnosticCapable.count) to create custom policy (select resourceType ALL to create a policy for each RP)"
                }
                catch
                {
                    Write-Warning -Message 'Invalid option, please try again.'
                }
            }
            $ResourceType = $DiagnosticCapable[$ResourceTypeToProcess -1].ResourceType
        }
        catch
        {
            if($SubscriptionId)
            {
                Throw write-host "No diagnostic capable resources available in selected subscription $SubscriptionID" -ForegroundColor Red
            }
        }
    }

    If($ResourceType -eq "ALL")
    {
        foreach($Type in $DiagnosticCapable|Where-Object {$_.ResourceType -ne "ALL"})
        {
            # Initialize metrics and logs JSON content
            $metricsArray = ''
            $logsArray = ''

            if($Type.logs)
            {
                $Logcategories = $Type.Categories
                $logsArray = New-LogArray $Logcategories
            }
            if($Type.metrics)
            {
                $metricsArray = New-MetricArray
                if($type.Logs)
                {
                    $metricsArray += ","
                }
            }
            if($ExportLA)
            {
                $sinkDest = "LA"
                $RPVar = Parse-ResourceType -resourceType $Type.ResourceType -sinkDest $sinkDest -kind $Type.Kind
                # If we have a kind for the resourceType let's add that to the policy evaluation rules (and add it to the displayname)
                if($Type.Kind)
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) `($($Type.Kind)`) to a Log Analytics Workspace"
                }
                elseif (!($Type.Kind))
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) to a Log Analytics Workspace"
                }
                
                # Create a Policy Name that is 64 chars (or less) using hash as an option [unique and repeatable]
                $ShortNameRT = Create-Hash -StringToHash $PolicyResourceDisplayName

                if($ExportInitiative)
                {
                    $JSONType = @'
{
    "type": "Microsoft.Authorization/policyDefinitions",
    "apiVersion": "2019-09-01",
    "name": "<SHORT NAME OF SERVICE>",

'@
                    # If we are exporting for Management Group - update RSID to support management group navigation
                    if($ManagementGroupDeployment)
                    {
                        $PolicyRSID = """[concat('/providers/Microsoft.Management/managementGroups/', parameters('TargetMGID'), '/providers/Microsoft.Authorization/policyDefinitions/', '$($ShortNameRT)')]"""
                    }
                    # If not exporting for MG, leverage standard ResourceID
                    else {
                        $PolicyRSID = """[resourceId('Microsoft.Authorization/policyDefinitions/', '$($ShortNameRT)')]"""
                    }
                        
                    
                    $PolicyRSIDs = $PolicyRSIDs + "                "  + $PolicyRSID + "," + "`r`n"
                    $JSONTYPE = $JSONType.replace("<SHORT NAME OF SERVICE>", "$($ShortNameRT)")
                    $PolicyJSON = Update-LogAnalyticsJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -JSONType $JSONType -ExportInitiative $ExportInitiative -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
                    $PolicyBag = $PolicyBag + $PolicyJSON[2] +  ',' + "`r`n"
                    $PolicyDefParam = @'
                    {
                        "policyDefinitionId": <PolicyResoureceID>,
                        <Policy Definition Parameters>
                    },
'@
                    $PolicyDefParam = $PolicyDefParam.Replace("<PolicyResoureceID>", "$($PolicyRSID)")
                    $PolicyDefParam = $PolicyDefParam.Replace("<Policy Definition Parameters>", "$($PolicyJSON[3])")
                    $PolicyDefParams = $PolicyDefParams + $PolicyDefParam + "`r`n"
                }
                else {
                    $JSONType = ''
                    $PolicyJSON = Update-LogAnalyticsJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
                }
                if(!($ExportInitiative))
                {
                    write-host "Exporting Log Analytics Custom Azure Policy for resourceType: $($Type.ResourceType)" -ForegroundColor Yellow
                    # Make sure export directory exists!
                    if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
                    {
                        try
                        {
                            $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                        }
                        catch
                        {
                            Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                            exit
                        }
                    }

                    # Clean Up JSON
                    $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
                    $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
                    $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

                    # outputting JSON for Azure Policy
                    $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
                    $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
                    $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force
                }
            }
            if($ExportEH)
            {
                $sinkDest = "EH"
                $RPVar = Parse-ResourceType -resourceType $Type.ResourceType -sinkDest $sinkDest -kind $Type.Kind
                # If we have a kind for the resourceType let's add that to the policy evaluation rules (and add it to the displayname)
                if($Type.Kind)
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) `($($Type.Kind)`) to a Regional Event Hub"
                }
                elseif (!($Type.Kind))
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) to a Regional Event Hub"
                }
                
                # Create a Policy Name that is 64 chars (or less) using hash as an option [unique and repeatable]
                $ShortNameRT = Create-Hash -StringToHash $PolicyResourceDisplayName

                if($ExportInitiative)
                {
                    $JSONType = @'
{
    "type": "Microsoft.Authorization/policyDefinitions",
    "apiVersion": "2019-09-01",
    "name": "<SHORT NAME OF SERVICE>",

'@
                    $PolicyRSID = """[resourceId('Microsoft.Authorization/policyDefinitions/', '$($ShortNameRT)')]"""
                    $PolicyRSIDs = $PolicyRSIDs + "                "  + $PolicyRSID + "," + "`r`n"
                    $JSONTYPE = $JSONType.replace("<SHORT NAME OF SERVICE>", "$($ShortNameRT)")
                    $PolicyJSON = Update-EventHubJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -JSONType $JSONType -ExportInitiative $ExportInitiative -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
                    $PolicyBag = $PolicyBag + $PolicyJSON[2] +  ',' + "`r`n"
                    $PolicyDefParam = @'
                {
                    "policyDefinitionId": <PolicyResoureceID>,
                    <Policy Definition Parameters>
                },
'@
                $PolicyDefParam = $PolicyDefParam.Replace("<PolicyResoureceID>", "$($PolicyRSID)")
                $PolicyDefParam = $PolicyDefParam.Replace("<Policy Definition Parameters>", "$($PolicyJSON[3])")
                $PolicyDefParams = $PolicyDefParams + $PolicyDefParam + "`r`n"
            }
            else {
                $JSONType = ''
                $PolicyJSON = Update-EventHubJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
            }
                if(!($ExportInitiative))
                {
                    write-host "Exporting Event Hub Custom Azure Policy for resourceType: $($Type.ResourceType)" -ForegroundColor Yellow

                    # Make sure export directory exists!
                    if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
                    {
                        try
                        {
                            $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                        }
                        catch
                        {
                            Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                            exit
                        }
                    }
                    # Clean Up JSON
                    $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
                    $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
                    $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

                    # outputting JSON for Azure Policy
                    $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
                    $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
                    $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force
                }
            }
            # Export for Storage Sink
            if($ExportStorage)
            {
                $sinkDest = "Storage"
                $RPVar = Parse-ResourceType -resourceType $Type.ResourceType -sinkDest $sinkDest -kind $Type.Kind
                # If we have a kind for the resourceType let's add that to the policy evaluation rules (and add it to the displayname)
                if($Type.Kind)
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) `($($Type.Kind)`) to a Regional Storage Account"
                }
                elseif (!($Type.Kind))
                {
                    $PolicyResourceDisplayName = "Apply Diagnostic Settings for $($Type.ResourceType) to a Regional Storage Account"
                }
                
                # Create a Policy Name that is 64 chars (or less) using hash as an option [unique and repeatable]
                $ShortNameRT = Create-Hash -StringToHash $PolicyResourceDisplayName

                if($ExportInitiative)
                {
                    $JSONType = @'
{
    "type": "Microsoft.Authorization/policyDefinitions",
    "apiVersion": "2019-09-01",
    "name": "<SHORT NAME OF SERVICE>",

'@
                    $PolicyRSID = """[resourceId('Microsoft.Authorization/policyDefinitions/', '$($ShortNameRT)')]"""
                    $PolicyRSIDs = $PolicyRSIDs + "                "  + $PolicyRSID + "," + "`r`n"
                    $JSONTYPE = $JSONType.replace("<SHORT NAME OF SERVICE>", "$($ShortNameRT)")
                    $PolicyJSON = Update-StorageJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -JSONType $JSONType -ExportInitiative $ExportInitiative -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
                    $PolicyBag = $PolicyBag + $PolicyJSON[2] +  ',' + "`r`n"
                    $PolicyDefParam = @'
                {
                    "policyDefinitionId": <PolicyResoureceID>,
                    <Policy Definition Parameters>
                },
'@
                $PolicyDefParam = $PolicyDefParam.Replace("<PolicyResoureceID>", "$($PolicyRSID)")
                $PolicyDefParam = $PolicyDefParam.Replace("<Policy Definition Parameters>", "$($PolicyJSON[3])")
                $PolicyDefParams = $PolicyDefParams + $PolicyDefParam + "`r`n"
            }
            else {
                $JSONType = ''
                $PolicyJSON = Update-StorageJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -kind $Type.Kind -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
            }
                if(!($ExportInitiative))
                {
                    write-host "Exporting Storage Custom Azure Policy for resourceType: $($Type.ResourceType)" -ForegroundColor Yellow

                    # Make sure export directory exists!
                    if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
                    {
                        try
                        {
                            $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                        }
                        catch
                        {
                            Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                            exit
                        }
                    }
                    # Clean Up JSON
                    $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
                    $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
                    $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

                    # outputting JSON for Azure Policy
                    $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
                    $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
                    $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force
                }
            }


        }
    }
    elseif (!($ExportInitiative))
    {
        # Initialize metrics and logs JSON content
        $metricsArray = ''
        $logsArray = ''
        if($DiagnosticCapable[$ResourceTypeToProcess -1].Logs)
        {
            $logcategories = $DiagnosticCapable[$ResourceTypeToProcess -1].Categories
            $logsArray = New-LogArray $Logcategories
        }
        else
        {

        }
        if($DiagnosticCapable[$ResourceTypeToProcess -1].Metrics)
        {
            $metricsArray = New-MetricArray
            if($DiagnosticCapable[$ResourceTypeToProcess -1].Logs)
            {
                $metricsArray += ","
            }
        }
        else
        {
 
        }
        if($ExportLA)
        {
            $RPVar = Parse-ResourceType -resourceType $ResourceType -sinkDest "LA" -kind $Type.Kind
            $PolicyJSON = Update-LogAnalyticsJSON -resourceType $ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
            write-host "Exporting Log Analytics Custom Azure Policy for resourceType: $($ResourceType)" -ForegroundColor Yellow
            # Make sure export directory exists!
            if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
            {
                try
                {
                    $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                }
                catch
                {
                    Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                    exit
                }
            }
            # Clean Up JSON
            $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
            $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
            $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

            # outputting JSON for Azure Policy
            $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
            $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
            $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force
        }
        if($ExportEH)
        {
            $RPVar = Parse-ResourceType -resourceType $ResourceType -sinkDest "EH" -kind $Type.Kind
            $PolicyJSON = Update-EventHubJSON -resourceType $ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
            write-host "Exporting Event Hub Custom Azure Policy for resourceType: $($ResourceType)" -ForegroundColor Yellow
            
            # Make sure export directory exists!
            if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
            {
                try
                {
                    $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                }
                catch
                {
                    Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                    exit
                }
            }
            # Clean Up JSON
            $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
            $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
            $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

            # outputting JSON for Azure Policy
            $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
            $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
            $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force

        }
        if($ExportStorage)
        {
            $RPVar = Parse-ResourceType -resourceType $ResourceType -sinkDest "Storage" -kind $Type.Kind
            $PolicyJSON = Update-StorageJSON -resourceType $ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1] -PolicyResourceDisplayName $PolicyResourceDisplayName -PolicyName $ShortNameRT
            write-host "Exporting Storage Custom Azure Policy for resourceType: $($ResourceType)" -ForegroundColor Yellow
            
            # Make sure export directory exists!
            if(!(Test-path "$($ExportDir)\$($RPVar[0])"))
            {
                try
                {
                    $NULL = new-item -ItemType Directory -Path "$($ExportDir)\$($RPVar[0])"
                }
                catch
                {
                    Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                    exit
                }
            }
            # Clean Up JSON
            $PolicyJSON[0] = Format-JSON -JSON $PolicyJSON[0]
            $PolicyJSON[1] = Format-JSON -JSON $PolicyJSON[1]
            $PolicyJSON[2] = Format-JSON -JSON $PolicyJSON[2]

            # outputting JSON for Azure Policy
            $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
            $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
            $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force

        }
    }
    if($ExportInitiative)
    {
        # If a template file was not specified for export, let's build one with what we know
        if(!($TemplateFileName))
        {
            $TemplateFileName = 'ARM-Template-azurepolicyinit.json'
        }
        # Otherwise, ensure we are doing our best to make sure the file is properly named (adding JSON extension and stripping folders)
        else {
            $TemplateFileName = ($TemplateFileName -split "\\")[-1]
            if(!($TemplateFileName.contains(".json")))
            {
                $TemplateFileName = $TemplateFileName + ".json"
            }
        }
        # Make sure export directory exists!
        if(!(Test-path $($ExportDir)))
        {
            try
            {
                $NULL = new-item -ItemType Directory -Path "$($ExportDir)"
            }
            catch
            {
                Write-Host "Failed to create output folder $ExportDir - exiting.." -ForegroundColor red 
                exit
            }
        }

        # If a display name was specified for Initiative, use it otherwise, let's build one according to what we know
        If($InitiativeDisplayName)
        {
            $InitiativeName = Create-Hash -StringToHash $InitiativeDisplayName
        }
        else
        {
            if($sinkDest -eq "EH")
            {
                $SinkName = "Regional Event Hub"
            }
            if($sinkDest -eq "LA")
            {
                $SinkName = "Log Analytics Workspace"
            }
            if($sinkDest -eq "Storage")
            {
                $SinkName = "Regional Storage Account"
            }
            $InitiativeDisplayName = "Azure Diagnostics Policy Initiative for $SinkName"
            $InitiativeName = Create-Hash -StringToHash $InitiativeDisplayName
        }

        # Building the Policy Initiative (Note only one sink point per policy initiative [Log Analytics or EventHub])
        $PolicyInititiative = New-PolicyInitiative -PolicyBag $PolicyBag -PolicyRSIDs $PolicyRSIDs -PolicyDefParams $PolicyDefParams -Parameters $PolicyJSON[0] -sinkDest $sinkDest -InitiativeDisplayName $InitiativeDisplayName -InitiativeName $InitiativeName -ManagementGroupDeployment $ManagementGroupDeployment
        
        # Ensure JSON is formatted on export
        $PolicyInititiative = Format-JSON -JSON $PolicyInititiative
        
        # Export Initiative
        try{
            $PolicyInititiative | Out-File "$($ExportDir)\$TemplateFileName" -Force
            Write-Host "Successfully wrote ARM template Policy Initiative to $($ExportDir)\$TemplateFileName" -ForegroundColor Yellow
        }
        catch{}

    }
}
# Function to validate JSON is correct with proper syntax
IF($ValidateJSON)
{
    Write-Host "Now Validating JSON in each exported policy artifact..." -ForegroundColor Cyan
    $Results = Validate-Json -ExportDir $ExportDir
    $InvalidCnt = $($Results| Where-Object {$_ -match "INVALID:*"}).count
    Write-Host "Total Valid Files Checked:" $($Results | Where-Object {$_ -match "VALID:*"}).count -ForegroundColor Green
    If($InvalidCnt -gt 0)
    {
        write-host "Total InValid Files Found:" $($Results| Where-Object {$_ -match "INVALID:*"}).count -ForegroundColor Yellow
        write-host "`nPlease review the following files for errors"
        write-host $($Results| Where-Object {$_ -match "INVALID:*"}) -ForegroundColor Yellow
    }
    else
    {
        write-host "Total Invalid Files Found: 0" -ForegroundColor Yellow
    }
}
$Stop = (Get-Date)
$Count = 0
try
{
    While(($ContextSet -ne $currentSub) -or ($Count -ge 5))
    {
        write-host "`nSetting Context back to initial subscription $CurrentSub"
        $SetContext = Set-AzContext -Subscription $CurrentSub
        $ContextSet = $SetContext.Subscription.Name
        $Count++
    }
}
catch
{
    Write-Host "Failed to set context back to intial subscription $CurrentSub.  Please review!"
}

Write-Host "Complete`n" -ForegroundColor Green
Write-Host "Script execution time: " -nonewline
Write-Host "$($($Stop - $Start).minutes) minutes and $($($Stop - $Start).seconds) seconds.`n" -ForegroundColor Cyan