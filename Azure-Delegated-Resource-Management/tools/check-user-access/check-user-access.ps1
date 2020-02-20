# Displays the current user's Owner permissions on subscriptions
function Get-AzSubOwnership {
    
    [cmdletbinding()]
    param($SubscriptionId, $SubscriptionName) 

    # Check if Az.Accounts and Az.Resources modules are installed.
    if (!(Get-Module "Az.Accounts") -or !(Get-Module "Az.Resources")) {
        Write-Output "Please install Az.Accounts and Az.Resources modules."
        exit
    }

    # Get Azure connection context for current user.
    $context = Get-AzContext
    Write-Host -nonewline "The current user ($($context.Account.Id)) "

    # Get new access token.
    # $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    # $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new($azureRmProfile)
    # $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
    # https://github.com/Azure/azure-powershell/issues/7752

    # Get all subscriptions user can access.
    $subs = Get-AzSubscription
    if (!$subs) {
        Write-Output "does not have access to any subscriptions."
        exit
    }

    # If specified as param, select subscription.
    if ($SubscriptionId) 
    {
        $subs = $subs | where-object {$_.Id -eq $SubscriptionId}

    }
    elseif ($SubscriptionName)
    {
        $subs = $subs | where-object {$_.Name -eq $SubscriptionName}
    }
    if (!$subs) {
        Write-Output "does not have access to the specified subscription, or the parameter is invalid."
        exit
    }
    
    # Display if user is Owner of subscription(s).
    $n = 0
    $output = foreach($sub in $subs)
    {
        select-azsubscription -SubscriptionId $sub.SubscriptionId > $null # Takes too much time!
        
        $roles = Get-AzRoleAssignment -SignInName $context.Account.Id -ExpandPrincipalGroups

        foreach($role in $roles){
            if ($role.RoleDefinitionName -eq "Owner") {
                $n++
                [pscustomobject]@{
                    SubscriptionName = $sub.Name;
                    SubscriptionId = $sub.Id;
                    DisplayName = $role.DisplayName;
                }
            }
        }
        
    }
    if ($n -eq 0) {
        Write-Output "is not an owner of any subscriptions."
    }
    else{
        Write-Output "is an Owner of:"
        $output | Format-Table
    }
    
}

