# Azure Policy to enforce Azure Monitoring on KeyVault

This template deploys a policy definition and an assignment, that will enforce Azure Monitor to be enabled KeyVaults, and route metrics and diagnostics data to the designated Log Analytics workspace.


>*NOTE*: When used in context of Azure Delegated Resource Management, there's a pre-req that the MSP have configured constrained delegation for the user(s) who will deploy this template to delegated customer subscriptions.