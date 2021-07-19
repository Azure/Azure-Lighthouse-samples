# Azure Policy to deploy Azure Lighthouse at Management Group-level

Pre-requisite: Register subscriptions for the Managed Services RP. Otherwise, the policy will not run. You can take a look at the following Logic Apps that automatically register the Managed Services RP:
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-partner
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-customer

Deploy this Policy at the management group level to delegate subscriptions within the management group to a managing tenant via Azure Lighthouse. 

`
New-AzManagementGroupDeployment -Name <nameofDeployment> -Location <location> -ManagementGroupId <nameOfMg> -TemplateFile <path to file> -TemplateParameterFile <path to parameter file> -verbose
`

This command will add the policy definition under the deployed mangement group. You need to create the assigment and remediation task for existing subscriptions.

This Policy has a DeployIfNotExists effect, evaluating subscriptions within a management group to determine if there are Lighthouse delegations. If not, then a deployment to the specified managing tenant is executed. 

