# Azure Policy to deploy Azure Lighthouse at Management Group-level

Deploy this Policy at the management group level to delegate subscriptions within the management group to a managing tenant via Azure Lighthouse. 

`New-AzManagementGroupDeployment -Name <nameofDeployment> -Location <location> -ManagementGroupId <nameOfMg> -TemplateFile <path to file> -verbose`

This Policy has a DeployIfNotExists effect, evaluating subscriptions within a management group to determine if there are Lighthouse delegations. If not, then a deployment to the specified managing tenant is executed. 
