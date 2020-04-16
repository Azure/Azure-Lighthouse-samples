# Check user access script

This script checks the current user's access to a given Azure subscription.


**NOTE:** Subscription-level deployment for Azure Lighthouse must be done by a non-guest account in the customer's tenant who has the [Owner built-in role](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#owner) for the subscription being onboarded (or which contains the resource groups that are being onboarded). To see all users who can delegate the subscription, a user in the customer's tenant can select the subscription in the Azure portal, open **Access control (IAM)**, and [view all users with the Owner role](../../role-based-access-control/role-assignments-list-portal.md#list-owners-of-a-subscription).

To learn more about onboarding customers to Azure Lighthouse, see [how to onboard a customer](https://docs.microsoft.com/azure/lighthouse/how-to/onboard-customer).