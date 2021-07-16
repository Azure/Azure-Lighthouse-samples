# Automatically register the Managed Services resource provider

<br/>

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjoanabmartins%2FAzure-Lighthouse-samples%2Fmaster%2Ftemplates%2Fregister-managed-services-rp%2Fazuredeploy.json)

 <br/>

## 1- Create a service principal
We are going to use an identity from the managing tenant to register the resource provider in the managed tenants. To do so, you need to go into the parent tenant and create an app registration:

 <p align="center">
  <img src="./media/aaad-appreg.PNG" >
</p>

Give it a name and select the multitenant option:

 <p align="center">
  <img src="./media/appreg-multitenant.PNG" >
</p>

Get the Application (client) ID, you will need it to deploy the template.

Create a secret for your app and save it in a safe place. After you create it, you won't be able to retrive it again. 

 <p align="left">
  <img src="./media/app-secret.PNG" >
</p>

<p align="left">
  <img src="./media/app-secret2.PNG" >
</p>

## 2- Grant your service principal access to the managed tenants

We to make it possible for the application that you just registered in the managing tenant, to exist in the managed tenants. To do so you need to [grant tenant-wide admin consent](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/grant-admin-consent#construct-the-url-for-granting-tenant-wide-admin-consent). You can do it by using an URL like this:
```http
https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={client-id}
```

where:

* `{client-id}` is the application's client ID (that you retrived above).
* `{tenant-id}` is your managed tenant ID 

You need to do that for every managed tenant.

This registers your service principal in all the customers tenants. Now, you need to give permissions to that service principal to be able to register the service provider in all subscription of those tenant. 

You can give this identity the role of contributor of the root management group, but that goes against the principle of least privileges. We advise you to create a more granular role (in each customer) to only give this service principal the possibility to register the managed services provider. 

### 2.1 Create and assign a custom role to the service provider
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

After you create the role, you will be able to assign that role to the service principal:

<p align="left">
  <img src="./media/roleassignment.PNG" >
</p>

## 3- Deploy template
Finally, we have everything set to deploy the logic app. You can click the button above and "Deploy to Azure" the logic app in the managing tenant.

You will need to fill in the following parameter:
* Resource Group Name - where you want the logic app and the connections to be deployed to
* Location
* Logic App Name - You should follow the naming convention that you have in your organization
* Application ID - The ID for the application that you created above
* Application secret - the secret that you retrived from the first step. 

> [!WARNING]
> For security reasons you should save the application ID and secret in a key vault and use the logic app identity to retrive it. That is really easy to do through the [system managed identity](https://docs.microsoft.com/en-us/azure/logic-apps/create-managed-service-identity) of the key vault and through the already existing [key vault / logic app connectors] (https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-securing-a-logic-app?tabs=azure-portal#secure-inputs-and-outputs-in-the-designer).

The logic app is configured to run every day, but you can change that trigger to better suit your needs.

