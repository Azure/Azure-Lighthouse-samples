# Azure Policy to create multiple, distinct delegations across a management group hierarchy
This policy is built for customers whom wish to deploy Azure Lighthouse at scale with **multiple** distinct offers within an enterprise management group structure. Most customers should leverage the default [policy-delegate-management-groups](../policy-delegate-management-groups/readme.md) policy unless there is a specific design need for distinct offers of different configurations within the same management group hierarchy. 

**Pre-requisite**: Register subscriptions within the management group for the Managed Services RP. Otherwise, the policy will not run. 

To automatically register the Managed Services RP, you can use the following Logic Apps:
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-partner
- https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/register-managed-services-rp-customer

This Azure Policy has a DeployIfNotExists effect, evaluating subscriptions within a management group to determine if there is an existing Azure Lighthouse delegation using **managedByName**. If not, then a deployment to the specified managing tenant is executed. When using this policy for **multiple** offers use unique policy names and **managedByName** parameters in addition to the specific delegations required.  

Use the following Powershell command to deploy this policy at the management group scope:

`
New-AzManagementGroupDeployment -Name <nameofDeployment> -Location <location> -ManagementGroupId <nameOfMg> -TemplateFile <path to file> -TemplateParameterFile <path to parameter file> -verbose
`


