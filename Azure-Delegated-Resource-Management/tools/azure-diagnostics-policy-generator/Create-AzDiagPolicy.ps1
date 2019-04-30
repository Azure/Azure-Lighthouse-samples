<#PSScriptInfo

.VERSION 1.0

.GUID e0962947-bf3c-4ed4-be3b-39cb7f6348c6

.AUTHOR jbritt@microsoft.com

.COMPANYNAME Microsoft

.COPYRIGHT Microsoft

.TAGS 

.LICENSEURI 

.PROJECTURI 
https://github.com/Azure/azure-policy/tree/master/samples/Monitoring

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
April 29, 2019 Initial
   Special thanks to John Kemnetz @jkemnetz (https://twitter.com/jkemnetz) for his initial project 
   here that I based some of my array logic off of for generation of JSON: https://github.com/johnkemnetz/azmon-onboarding/tree/master/policies

   Thanks to Tao Yang @MrTaoYang (https://twitter.com/MrTaoYang) for his collaboration initially and his 
   hard work he has done here: https://blog.tyang.org/2018/11/19/configuring-azure-resources-diagnostic-log-settings-using-azure-policy/
   that he has created to support our community in this space!

   And thank you Nick Kiest from the Azure Monitor Product Team for supporting the project from their side seeing value in the effort!

   Finally Kristian Nese @KristianNese (https://twitter.com/KristianNese) from AzureCAT for his direct support on feedback as I navigated this effort and for him providing technical expertize in this space.
#>

<#  
.SYNOPSIS  
  Create a custom policy to enable Azure Diagnostics and send that data to a Log Analytics Workspace or Regional Event Hub
  
  Note  This script currently supports onboarding Azure resources that support Azure Diagnostics (metrics and logs) to Log Analytics and Event Hub
  
.DESCRIPTION  
  This script takes a SubscriptionID, ResourceType, ResourceGroup as parameters, analyzes the subscription or
  specific ResourceGroup defined for the resources specified in $Resources, and builds a custom policy for diagnostic metrics/logs
  for Event Hubs and Log Analytics as sink points for selected resource types.

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

.PARAMETER ValidateJSON
    If specified will do a post export validation recursively against the export directory or will validate JSONs recursively in current script
    directory and subfolders or exportdirectory (if specified).

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
  .\Create-AzDiagPolicy.ps1 -ValidateJSON -ExportDir "EH-Policies"
  Will leverage the specified export directory (relative to current working directory of PS console or specify fully qualified directory)
  and will validate all JSON files to ensure they have no syntax errors

.NOTES
   AUTHOR: Microsoft Log Analytics Team / Jim Britt Senior Program Manager - Azure CAT 
   LASTEDIT: April 29, 2019

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
#>

param
(
    # Export all policies without prompting - default is false
    [Parameter(Mandatory=$False)]
    [switch]$ExportAll=$False,

    # Export Event Hub Specific Policies
    [Parameter(Mandatory=$False)]
    [switch]$ExportEH=$False,

    # Export Log Analytics Specific Policies
    [Parameter(Mandatory=$False)]
    [switch]$ExportLA=$False,

    # Validate all exported policies to ensure they are proper JSON
    [Parameter(Mandatory=$False)]
    [switch]$ValidateJSON=$False,    

    # Provide SubscriptionID to bypass subscription listing
    [Parameter(Mandatory=$False)]    
    [guid]$SubscriptionId,

    # Add ResourceType to reduce scope to Resource Type instead of entire list of resources to scan
    [Parameter(Mandatory=$False)]
    [string]$ResourceType,

    # Add a ResourceGroup name to reduce scope from entire Azure Subscription to RG
    [Parameter(Mandatory=$False)]
    [string]$ResourceGroupName,

    # Add a ResourceName name to reduce scope from entire Azure Subscription to specific named resource
    [Parameter(Mandatory=$False)]
    [string]$ResourceName,

    # Export Directory Path for Artifacts - if not set - will default to script directory
    [Parameter(Mandatory=$False)]
    [string]$ExportDir
)
# FUNCTIONS
# Get the ResourceType listing from all ResourceTypes capable in this subscription
# to be sent to log analytics - use "-ResourceType" param to bypass
function Get-ResourceType (
    [Parameter(Mandatory=$True)]
    [array]$allResources
    )
{
    $analysis = @()
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
        $URI = "https://management.azure.com/$($Resource.ResourceId)/providers/microsoft.insights/diagnosticSettingsCategories/?api-version=2017-05-01-preview"
        
        if (! $analysis.where({$_.ResourceType -eq $resource.ResourceType}))
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
                }
                $ResponseJSON = $Status.Content|ConvertFrom-Json
                
                # If logs are supported or metrics on each resource, set value as $True
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
                
            }
            catch {}
            finally
            {
                if(!($Invalid))
                {
                    $object = New-Object -TypeName PSObject -Property @{'ResourceType' = $resource.ResourceType; 'Metrics' = $metrics; 'Logs' = $logs; 'Categories' = $Categories}
                    $analysis += $object
                }
            }
        }
    }
    # Return the list of supported resources
    $object = New-Object -TypeName PSObject -Property @{'ResourceType' = "All"; 'Metrics' = "True"; 'Logs' = "True"; 'Categories' = "Various"}
    $analysis += $object
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
    [string]$nameField
)
{
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
                    }
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

$JSONVar = @'
{
    "properties": {
        "displayName": "Apply Diagnostic Settings for <NAME OF SERVICE> to a Log Analytics workspace",
        "mode": "Indexed",
        "description": "This policy automatically deploys diagnostic settings for <NAME OF SERVICE> to a Log Analytics workspace.",
        "metadata": {
            "category": "Monitoring"
        },
        "parameters": <INSERT Parameters>,
        "policyRule": <INSERT Policy Rules>
    }
}
'@
    # Update Content according to type, categories, fullname or name
    $JSONVar = $JSONVar.replace('<NAME OF SERVICE>', $ResourceType)

    # Output content for Azure Rules file
    $JSONRules = $JSONRules.replace('<RESOURCE TYPE>', $ResourceType)
    $JSONRules = $JSONRules.replace('<METRICS ARRAY>', $metricsArray)
    $JSONRules = $JSONRules.replace('<LOGS ARRAY>', $logsArray)
    $JSONRules = $JSONRules.replace('<NAME OR FULLNAME>', $nameField)

    # Merge components to build azurepolicy output content
    $AzurePolicyJSON = $JSONVar
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Parameters>', $JSONPARMS)
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Policy Rules>',$JSONRULES)

    # Build the separate JSON payloads into an array
    $JSONARRAY += $JSONPARMS
    $JSONARRAY += $JSONRULES
    $JSONARRAY += $AzurePolicyJSON
    
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
    [string]$nameField
)
{
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
                    }
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
                                "equals": "[parameters('eventHubName')]"
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
                                            "eventHubName": "[parameters('eventHubName')]",
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

$JSONVar = @'
{
    "properties": {
        "displayName": "Apply Diagnostic Settings for <NAME OF SERVICE> to a regional Event Hub",
        "mode": "Indexed",
        "description": "This policy automatically deploys diagnostic settings for <NAME OF SERVICE> to a regional event hub.",
        "metadata": {
            "category": "Monitoring"
        },
        "parameters": <INSERT Parameters>,
        "policyRule": <INSERT Policy Rules>
    }
}
'@    

    # Update Content according to type, categories, fullname or name
    $JSONVar = $JSONVar.replace('<NAME OF SERVICE>', $ResourceType)

    # Output content for Azure Rules file
    $JSONRules = $JSONRules.replace('<RESOURCE TYPE>', $ResourceType)
    $JSONRules = $JSONRules.replace('<METRICS ARRAY>', $metricsArray)
    $JSONRules = $JSONRules.replace('<LOGS ARRAY>', $logsArray)
    $JSONRules = $JSONRules.replace('<NAME OR FULLNAME>', $nameField)

    # Merge components to build azurepolicy output content
    $AzurePolicyJSON = $JSONVar
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Parameters>', $JSONPARMS)
    $AzurePolicyJSON = $AzurePolicyJSON.Replace('<INSERT Policy Rules>',$JSONRULES)

    # Build the separate JSON payloads into an array
    $JSONARRAY += $JSONPARMS
    $JSONARRAY += $JSONRULES
    $JSONARRAY += $AzurePolicyJSON
    
    # Send the payload
    $JSONARRAY    
}

function Parse-ResourceType
(
    [Parameter(Mandatory=$True)]
    [string]$resourceType,
    [Parameter(Mandatory=$True)]
    [string]$sinkDest

)
{
    $ReturnVar=@()
    if($ResourceType.Split("/").count -eq 3)
    {
        $nameField = "fullName"
        $DirectoryNameBase = "Apply-Diag-Settings-$sinkDest-" + $($resourceType.Split("/", 3))[0] + "-" + $($resourceType.Split("/", 3))[1] + "-" + $($resourceType.Split("/", 3))[2]
    }
    if($ResourceType.Split("/").count -eq 2)
    {
        $nameField = "name"
        $DirectoryNameBase = "Apply-Diag-Settings-$sinkDest-" + $($resourceType.Split("/", 2))[0] + "-" + $($resourceType.Split("/", 2))[1]
    }
    $ReturnVar += $DirectoryNameBase
    $ReturnVar += $nameField
    $ReturnVar
}

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

# MAIN SCRIPT
if ($MyInvocation.MyCommand.Path -ne $null)
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
IF(!$($ExportEH) -and !($ExportLA) -and !($ValidateJSON))
{
    write-host "Nothing to do - please use either parameter -ExportLA, -ExportEH, -ValidateJSON (or all three) to export / validate policies" -ForegroundColor Yellow
    Set-Location $CurrentDir
    exit
}

If(!($ExportDir))
{
    $ExportDir = $CurrentDir
}

#Variable Definitions
[array]$Resources = @()

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 
    if($Token.ExpiresOn -lt $(get-date))
    {
        "Logging you out due to cached token is expired for REST AUTH.  Re-run script"
        $null = Disconnect-AzAccount        
    } 
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
    $currentContext = Get-AzContext
    $token = $currentContext.TokenCache.ReadItems() | Where-Object {$_.tenantid -eq $currentContext.Tenant.Id} 

}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
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

# Determine which resourcetype to search on
[array]$ResourcesToCheck = @()
[array]$DiagnosticCapable=@()
[array]$Logcategories = @()

IF($($ExportEH) -or ($ExportLA))
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
    $ResourcesToCheck = Get-AzResource @FindResourceParams 

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
        Write-Host "Gathering a list of monitorable Resource Types from Azure Subscription ID " -NoNewline -ForegroundColor Cyan
        Write-Host "$SubscriptionId..." -ForegroundColor Yellow
        try
        {
            $DiagnosticCapable = Add-IndexNumberToArray (Get-ResourceType $ResourcesToCheck).where({$_.metrics -eq $True -or $_.Logs -eq $True}) 

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
            Throw write-host "No diagnostic capable resources available in selected subscription $SubscriptionID" -ForegroundColor Red
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
                $RPVar = Parse-ResourceType -resourceType $Type.ResourceType -sinkDest "LA"
                $PolicyJSON = Update-LogAnalyticsJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1]
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
                # outputting JSON for Azure Policy
                $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
                $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
                $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force                
            }
            if($ExportEH)
            {
                $RPVar = Parse-ResourceType -resourceType $Type.ResourceType -sinkDest "EH"
                $PolicyJSON = Update-EventHubJSON -resourceType $Type.ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1]
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
                # outputting JSON for Azure Policy
                $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
                $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
                $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force                
            }

        }
    }
    else
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
            $RPVar = Parse-ResourceType -resourceType $ResourceType -sinkDest "LA"
            $PolicyJSON = Update-LogAnalyticsJSON -resourceType $ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1]
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

            # outputting JSON for Azure Policy
            $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
            $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
            $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force
        }
        if($ExportEH)
        {
            $RPVar = Parse-ResourceType -resourceType $ResourceType -sinkDest "EH"
            $PolicyJSON = Update-EventHubJSON -resourceType $ResourceType -metricsArray $metricsArray -logsArray $logsArray -nameField $RPVar[1]
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

            # outputting JSON for Azure Policy
            $PolicyJSON[0] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.parameters.json" -Force
            $PolicyJSON[1] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.rules.json" -Force
            $PolicyJSON[2] | Out-File "$($ExportDir)\$($RPVar[0])\azurepolicy.json" -Force

        }
    }
}

IF($ValidateJSON)
{
    Write-Host "Now Validating JSON in each exported policy..." -ForegroundColor Cyan
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
Write-Host "Complete" -ForegroundColor Green