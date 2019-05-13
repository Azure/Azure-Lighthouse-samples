<#
.Synopsis
   Runbook for Azure Resource Manager Analytics
.DESCRIPTION
   This Runbook does an assessment on your ARM template deployments, Resource Locks, resource usage, tags and RAC.
.AUTHOR
    Kristian Nese (Kristian.Nese@Microsoft.com) AzureCAT
#>

# Login to Azure using RunAs account in Azure Automation

"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

"Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid 

# Collecting Automation variables - created by the Azure Resource Manager Template

$OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
$OMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
$AzureSubscriptionId = Get-AutomationVariable -Name 'AzureSubscriptionId'
$AzureTenantId = Get-AutomationVariable -Name 'AzureTenantId'

# It's 5 o'clock somewhere...

# Getting an overview of all ARM Deployments

$ResourceGroups = Get-AzureRmResourceGroup

foreach ($resourcegroup in $ResourceGroups) {
    $Deployments = Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourcegroup.ResourceGroupName 

    $DeploymentTable = @()
    foreach ($Deployment in $Deployments) {
        $DeploymentData = new-object psobject -Property @{
            ResourceGroupName = $Deployment.ResourceGroupName;
            SubscriptionId = $AzureSubscriptionId;
            TenantId = $AzureTenantId;
            DeploymentName = $Deployment.DeploymentName;
            ProvisioningState = $Deployment.ProvisioningState;
            TimeStamp = $Deployment.TimeStamp.ToUniversalTime().ToString('yyyy-MM-ddtHH:mm:ss');
            Mode = $Deployment.Mode.ToString();
            Parameters = $deployment.Parameters.Keys | %{
                @{
                    $_ = $Deployment.Parameters.Item($_)
                }
            }
            Outputs = $Deployment.Outputs.Keys + $deployment.Outputs.Values;
            TemplateLink = $Deployment.TemplateLink;
            CorrelationId = $Deployment.CorrelationId.ToString()
            Log = 'Deployments'
        }

    $DeploymentTable += $DeploymentData

    $DeploymentsJson = ConvertTo-Json -inputobject $deploymenttable -Depth 100

    Write-Output $DeploymentsJson 
    
    $LogType = 'AzureManagement'

    Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $omsworkspaceKey -body $DeploymentsJson -logType $LogType
    }
}
# Getting an overview of all existing Azure resources
    
$Resources = Get-AzureRmResource 

    foreach ($resource in $resources)
    {
        $ResourcesTable = @()
        $ResourcesData = new-object psobject -Property @{
            ResourceType = $Resource.ResourceType;
            ResourceGroupName = $Resource.ResourceGroupName;           
            Location = $Resource.Location;
            ResourceName = $Resource.Name;
            ResourceId = $Resource.ResourceId;
            SubscriptionId = $Resource.SubscriptionId;
            TenantId = $AzureTenantId;
            Log = 'Resources'
            }

        $ResourcesTable += $ResourcesData
        
        $ResourcesJson = ConvertTo-Json -InputObject $ResourcesTable

        Write-Output $ResourcesJson 

        $LogType = 'AzureManagement'

        Send-OMSAPIIngestionData -customerId $omsworkspaceid -sharedKey $omsworkspaceKey -body $ResourcesJson -logType $LogType
    }

    $locks = Get-AzureRmResourceLock

        foreach ($lock in $locks)
        {
            $LockTable = @()
            $LockData = new-object psobject -property @{
                Name = $lock.Name;
                Log = 'Lock';
                ResourceName = $lock.ResourceName;
                ResourceType = $lock.ResourceType;
                SubscriptionId = $AzureSubscriptionId;
                TenantId = $AzureTenantId;
                LockId = $lock.LockId;
                ResourceId = $lock.ResourceId;
                ExtensionResourceType = $lock.ExtensionResourceType;
                Properties = $lock.properties
                }
            $LockTable += $LockData
            $LockJson = ConvertTo-Json -inputobject $locktable
            
            $LogType = 'AzureManagement'
            
            Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $OMSWorkspaceKey -body $LockJson -logType $LogType
        }
