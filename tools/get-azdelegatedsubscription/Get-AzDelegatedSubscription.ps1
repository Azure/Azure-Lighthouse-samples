function Get-AzDelegatedSubscription {
    [cmdletbinding()]
    param ()

    # Getting Azure connection context for the signed in user
    $currentContext = Get-AzContext

    # fetching new token
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new($azureRmProfile)
    $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)

    # Listing All Subscriptions to grab their tenantId's
    $listSubscriptions = @{
        Uri = 'https://management.azure.com/subscriptions?api-version=2019-07-01'
        Headers = @{
            Authorization = "Bearer $($token.AccessToken)"
            'Content-Type' = 'application/json'
        }
        Method = 'GET'
    }
    $list = Invoke-RestMethod @listSubscriptions

    # Filtering the output to only show the delegated subscriptions
    $delegatedSubsValue = $list.value
    $delegatedSubsValue | Where-Object -FilterScript { $_.tenantId -ne $token.TenantId }
}
