# Displays the current user's Owner permissions on subscriptions

# test in Lighthouse Demo account
function Get-AzOwnerAssignment {
    
    # [cmdletbinding()]
    param($SubscriptionId, $SubscriptionName) 

    # Check if Az.Accounts and Az.Resources modules are installed.
    # depending on default paths? what's up?
    #if (!(Get-Module "Az.Accounts") -or !(Get-Module "Az.Resources")) {
    #    Write-Output "Please install Az.Accounts and Az.Resources modules."
    #    exit
    #}

    # Get Azure connection context for current user.
    $context = Get-AzContext
    Write-Host -nonewline "The current user ($($context.Account.Id)) "

    # Get new access token.
    # $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    # $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new($azureRmProfile)
    # $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
    # https://github.com/Azure/azure-powershell/issues/7752

    # Check if user is an Owner of the specificed subscription.
    if ($SubscriptionId -or $SubscriptionName) {
        try {
            if ($SubscriptionId) {
                select-azsubscription -subscriptionId $SubscriptionId -ErrorAction Stop > $null
            }
            elseif ($SubscriptionName) {
                select-azsubscription -subscriptionName $SubscriptionName -ErrorAction Stop > $null
            }
        }
        catch
        {
            Write-Output "does not have access to this subscription. Please provide a valid subscription."
            exit
        }
        $owner = Get-AzRoleAssignment -SignInName $context.Account.Id -RoleDefinitionName "Owner" -ExpandPrincipalGroups
        if ($owner) {
            Write-Output "is an Owner of the subscription (DisplayName: $($owner.DisplayName))."
        }
        else {
            Write-Output "is not an Owner of the subscription."
        }
    }
    
    # If there is no parameter, check all subscriptions user can access.
    else {
        $subs = Get-AzSubscription
        $output = foreach($sub in $subs)
        {
            select-azsubscription -SubscriptionId $sub.SubscriptionId > $null 
            $owner = Get-AzRoleAssignment -SignInName $context.Account.Id -RoleDefinitionName "Owner" -ExpandPrincipalGroups -ErrorAction SilentlyContinue
            if ($owner) {
                [pscustomobject]@{
                    SubscriptionName = $sub.Name;
                    SubscriptionId = $sub.Id;
                    DisplayName = $owner.DisplayName;
                }
            }
        }
        Write-Output "is an Owner of $($output.count) subscriptions."
        $output | Format-Table
    }
    
}

