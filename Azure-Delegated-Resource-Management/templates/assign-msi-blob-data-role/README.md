# Assign MSI data plane roles to blob storage

The provider in Azure Lighthouse currently (as of Mar 2020) cannot perform data plane operations using Azure Active Directory identities. However, the applications that providers offer to their customers often need to perform data operations on Azure Storage.  An elegant solution for this is to create a [Managed Service Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) (MSI) for the application, and assign the application data plane roles to access Azure Storage.  This can all be done in the provider's context without logging into the customer's tenant.

This template [demonstrates](assignBlobDataRoleMSI.json#L45) how to assign an Azure Web App the [Storage Blob Data Reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader) role to an Azure Storage Account.  Note that you must include this role when you request the ```User Access Administrator``` permission from the customer as documented [here](https://docs.microsoft.com/en-us/azure/lighthouse/concepts/tenants-users-roles#role-support-for-azure-delegated-resource-management).

This template also [demonstrates](assignBlobDataRoleMSI#57) how to assign the Web App the [Storage Blob Delegator](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-delegator) role to a container in the Storage Account.  This allows the Web App to [generate SAS URLs with UserDelegationKey](https://docs.microsoft.com/en-us/rest/api/storageservices/delegate-access-with-shared-access-signature#types-of-shared-access-signatures) rather than Storage Account key.  This role is a control plane role.  This sample demonstrates the not-so-obvious syntax that must be followed when assigning roles to specific resources:

```
"type": "{resourceType}/providers/roleAssignments",
"name": "{resourceName}/Microsoft.Authorization/{uniqueId}",
```

For Blob Storage Container, it must be specified as following:
```
"type": "Microsoft.Storage/storageAccounts/blobServices/containers/providers/roleAssignments",
"name": "{storageAccountName}/default/{containerName}/Microsoft.Authorization/{uniqueId}",
"scope": "{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}/blobServices/default/containers/{containerName}"
```

The ```scope``` field is not required in this case. If you do specify it, it must match what's specified in ```type``` and ```name``` as shown above.

>*NOTE*: Although Lighthouse currently doesn't support data plane operations on Azure Storage Account, the provider could still access data with a Storage Account Key.  This is because [listing Storage Account Keys is a control plane operation](https://docs.microsoft.com/en-us/azure/storage/common/authorization-resource-provider?toc=/azure/storage/blobs/toc.json#built-in-roles-for-management-operations).  However, the MSI approach demonstrated above is superior in security and should be used when possible. 