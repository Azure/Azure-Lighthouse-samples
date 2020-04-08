# Azure Policy to enforce Azure Monitoring on subscription

This template deploys several Azure policies that will enforce Azure Monitor to be enabled on the subscription, and connects all Windows & Linux VMs to the policy created Log Analytics workspace.


>*NOTE*: When used in context of Azure Delegated Resource Management, there's a pre-req that the MSP have configured constrained delegation for the user(s) who will deploy this template to delegated customer subscriptions.