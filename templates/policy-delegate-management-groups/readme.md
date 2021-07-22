# Azure Policy to delegate all subscriptions in a Management Group

**Pre-requisite**: Register subscriptions within the management group for the Managed Services RP. Otherwise, the policy will not run. 

To automatically register the Managed Services RP, you can use the following Logic Apps:
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-partner
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-customer

This Azure Policy has a DeployIfNotExists effect, evaluating subscriptions within a management group to determine if there are Azure Lighthouse delegations. If not, then a deployment to the specified managing tenant is executed. 

Use the following Powershell command to deploy this policy at the management group scope:

`
New-AzManagementGroupDeployment -Name <nameofDeployment> -Location <location> -ManagementGroupId <nameOfMg> -TemplateFile <path to file> -TemplateParameterFile <path to parameter file> -verbose
`


