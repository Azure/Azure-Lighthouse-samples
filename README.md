
# Microsoft Azure Lighthouse

Azure Lighthouse provides capabilities for partners to perform cross customer management at scale.  We do this by providing you the ability to view and manage multiple customers from a single context. When you log into Azure, you can see all of your customers who are using Azure Lighthouse. [Learn more](https://azure.com/lighthouse).

This repository contains samples to help you use Azure Resource Manager to configure [Azure delegated resource management](https://docs.microsoft.com/azure/lighthouse/concepts/azure-delegated-resource-management) and to configure monitoring and management of customer environments.


Name | Description   | Auto-deploy   | Manual deploy |
-----| ------------- |--------------- |------- 
| Azure Lighthouse - Subscription Deployment |onboard customers' *subscriptions* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management%2FdelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management)
| Azure Lighthouse - Resource Group Deployment | onboard customers' *resource groups* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegated-resource-management%2FrgDelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegated-resource-management)
| Azure Lighthouse - Multiple Resource Group Deployment | onboard customers' *resource groups* | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegated-resource-management%2FmultipleRgDelegatedResourceManagement.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegated-resource-management)
| Azure Lighthouse + Azure AD PIM - Subscription Deployment  | onboard customers' *subscriptions* using **Azure AD PIM** | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fdelegated-resource-management-eligible-authorizations%2FdelegatedResourcemanagement-eligible-authorizations.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/delegated-resource-management-eligible-authorizations)
| Azure Lighthouse + Azure AD PIM - Resource Group Deployment | onboard customers' *resource groups* using **Azure AD PIM** | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegatedResourceManagement-eligible-authorizations%2Frg-delegatedResourcemanagement-eligible-authorizations.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegatedResourceManagement-eligible-authorizations)
| Azure Lighthouse + Azure AD PIM - Multiple Resource Group Deployment | onboard customers' *resource groups* using **Azure AD PIM** | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Frg-delegatedResourceManagement-eligible-authorizations%2FmultipleRgDelegatedResourceManagement-eligible-authorizations.json) | [templates](https://github.com/Azure/Azure-Lighthouse-samples/tree/master/templates/rg-delegatedResourceManagement-eligible-authorizations)

**Note for customers using Azure Lighthouse+Azure AD PIM: **  *All Azure Lighthouse+Azure AD PIM functionality is currently in **private preview**. If you are a customer onboarding your scopes to Azure Lighthouse for management and your service provider is using Azure AD PIM functionality, you may see a governance API error message if your subscription is not whitelisted for Azure Lighthouse+PIM preview. Simply request to whitelist the subscription your are trying to delegate to resolve this error*

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
