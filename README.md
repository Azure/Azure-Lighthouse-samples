
# Microsoft Azure Lighthouse

Azure Lighthouse provides capabilities to perform cross-tenant management at scale.  We do this by providing you the ability to view and manage multiple customers from a single context. When you log into Azure, you can see all of your customers who you are managing through Azure Lighthouse. [Learn more](https://azure.com/lighthouse).

This repository contains samples to help you use Azure Resource Manager to configure [Azure delegated resource management](https://docs.microsoft.com/azure/lighthouse/concepts/azure-delegated-resource-management) and to configure monitoring and management of customer environments.

The templates shown below can be used to [onboard a customer to Azure Lighthouse](https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer). You can deploy these manually, or use the "Deploy to Azure" buttons to deploy directly in the Azure portal.
# Deploy to Azure buttons

Name | Description   | Auto-deploy   | Manual deploy |
-----| ------------- |--------------- |------- 
| Azure Lighthouse - Subscription Deployment |onboard a *subscription* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management%2FdelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management)
| Azure Lighthouse - Resource Group Deployment | onboard a *resource group* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegated-resource-management%2FrgDelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegated-resource-management)
| Azure Lighthouse - Multiple Resource Group Deployment | onboard multiple *resource groups* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegated-resource-management%2FmultipleRgDelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegated-resource-management)
| Azure Lighthouse + Azure AD PIM - Subscription Deployment  | onboard a *subscription* using **Azure AD PIM** (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Fsubscription%2Fsubscription.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/subscription)
| Azure Lighthouse + Azure AD PIM - Resource Group Deployment | onboard a *resource group* using **Azure AD PIM** (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Frg%2Frg.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/rg)
| Azure Lighthouse + Azure AD PIM - Multiple Resource Group Deployment | onboard multiple *resource groups* using **Azure AD PIM** (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Frg%2Fmultiple-rg.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/rg)
| Azure Lighthouse + Azure AD PIM Managing Tenant Approvers - Subscription Deployment | onboard a *subscription* using **Azure AD PIM** with support for Managing tenant approvers (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Fsubscription%2Fsubscription-managing-tenant-approvers.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/subscription)
| Azure Lighthouse + Azure AD PIM Managing Tenant Approvers - Resource Group Deployment | onboard a *resource group* using **Azure AD PIM** with support for Managing tenant approvers (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Frg%2Frg-managing-tenant-approvers.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/rg)
| Azure Lighthouse + Azure AD PIM Managing Tenant Approvers - Multiple Resource Group Deployment | onboard multiple *resource groups* using **Azure AD PIM** with support for Managing tenant approvers (preview) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2Frg%2Fmultiple-rg-managing-tenant-approvers.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations/rg)


**Special Instructions (for MSPs):**
To customize, fork this repository, and follow [these](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button) instructions to update the links to enable your customers to deploy your templates into their Azure environments.
# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
