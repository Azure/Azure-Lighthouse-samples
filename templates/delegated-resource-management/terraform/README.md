# Deploy Azure Lighthouse using a Terraform template

This template deploys Azure Lighthouse using Terraform.

## Getting started

Same as when using ARM templates to onboard a customer in Azure Lighthouse, you have to fill out parameters and configure your Terraform template and a user in the customer's tenant must deploy it within their tenant. A separate deployment is needed for each subscription that you want to onboard (or for each subscription that contains resource groups that you want to onboard). Make sure to review this procedure to understand [how to onboard a customer](https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer).

To run the terraform template the customer can use their own pipelines or Azure Cloud Shell as described here for [bash](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash) or for [PowerShell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-powershell?tabs=bash).

## Running the template

To run the automation from the customer tenant follow the next steps:

- Provide the environment variables in the [vars.sh](./scripts/vars.sh). To obtain the values for the environment variables, review [this document](https://docs.microsoft.com/en-us/azure/lighthouse/how-to/onboard-customer). For the scope, it can be either a subscription or a resource group, make sure it matches the format:

  - Subscription: "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  - Resource Group: "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myResourceGroup"

- Run the [vars.sh](./scripts/vars.sh) script by executing this command:

    ```bash
    . ./vars.sh
    ```

- Run the terraform init command which will initialize Terraform, creating the state file to track our work:

    ```bash
    terraform init
    ```

- Onboard Azure Lighthouse by running the command below. Wait for the plan to finish:

    ```bash
    terraform apply --auto-approve
    ```

- Once Terraform has completed its run crosstenant visibility should be enabled.
