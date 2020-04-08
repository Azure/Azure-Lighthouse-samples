# Azure Alert for delegation operations

For customers who want to monitor their subscriptions, and have activity logs sent to Log Analytics, this template deploys an Azure Alert based on a log search.

Pre-reqs:
- Log Analytics workspace
- Action Group (if resourceId for existing action group is not specified, provide a resource name and the template will create a new one)
