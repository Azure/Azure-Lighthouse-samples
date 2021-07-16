# Use a logic app in the customer environment to automatically register the Managed Services resource provider in all subscriptions

<br/>

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjoanabmartins%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fregister-managed-services-rp%2Fazuredeploy.json)

 <br/>

This logic app goal is to register the Managed Services resource provider in all subscriptions. This will help the policy to deploy Azure Lighthouse at the Management group level to properly work, without you having to register the managed services resource provider manually. 

The logic app that you find here is intended to be **deployed for each customer**. There is a similar example in this repository, where you can find a logic app that will do the same thing, but you can deploy that in the partner enviornment.

## **Post-Deployment configurations**
## 1- Grant permissions to the logic app to be able to register the provider in each subscription
The logic app template that you can deploy above, will create a system assigned identity in the customer AAD. You will need to manually give permissions for that identity to be able to get all subscriptions and register the managed services resource provider.

You can give this identity the role of contributor of the root management group, but that goes against the principle of least privilege. We advise you to create a more granular role (in each customer). This role will only give permission to register the managed services provider. 

### **1.1 Create and assign a custom role to the managed identity**
There are multiple ways to [create a custom role definition](https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles).

You can find the definition of the custom role in the file *managedServicesRPRegister-role.json*. Don't forget to change in the file the *assignables scopes* field with the Root Management Group:
```json
"AssignableScopes": [
      "/providers/Microsoft.Management/managementGroups/<rootMGID>"
    ]
```     
To deploy it, you can use Azure CLI or Powerhsell:
```azurecli
az role definition create --role-definition "~roles/managedServicesRPRegister-role.json"
``` 
```azurepowershell
New-AzRoleDefinition -InputFile "C:\CustomRoles\managedServicesRPRegister-role.json"
```

After you create the role, you will be able to assign that role to the logic app system assigned identity. You should assign it at the *root management group level*, so that it will find each new subscription. To find it better you can look for the name that you gave your logic app:
<p align="left">
  <img src="./media/roleassignment.png" >
</p>

## 

The logic app is configured to run every day, but you can change that trigger to better suit your needs.

