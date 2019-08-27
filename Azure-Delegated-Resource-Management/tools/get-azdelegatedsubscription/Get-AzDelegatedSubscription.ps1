function Get-AzDelegatedSubscription {
    [cmdletbinding()]
    param ()
    begin {
        # Getting Azure connection context for the signed in user
        $currentContext = Get-AzContext
        $token = $currentContext.TokenCache.ReadItems() | ? {$_.tenantid -eq $currentContext.Tenant.Id}
    }
    process {
    # Getting Home Tenant Id
    $getTenant = @{
        Uri = "https://management.azure.com/tenants?api-version=2019-07-01"
        Headers = @{
            Authorization = "Bearer $($token.AccessToken)"
            "Content-Type" = "application/json"
        }
        Method = "GET"
    }
    $tenant = Invoke-WebRequest @getTenant
    $tenantContent = ConvertFrom-Json -InputObject $tenant.content
    $tenantId = $tenantContent.value.id.Split('/')[2]

    # Listing All Subscriptions to grab their tenantId's
    $listSubscriptions = @{
        Uri = "https://management.azure.com/subscriptions?api-version=2019-07-01"
        Headers = @{
            Authorization = "Bearer $($token.AccessToken)"
            "Content-Type" = "application/json"
        }
        Method = "GET"
    }
    $list = Invoke-WebRequest @listSubscriptions    
    $output = ConvertFrom-Json -InputObject $list.Content
    }

    end {
    # Filtering the output to only show the delegated subscriptions
    Write-Host "Preparing list of delegated subscriptions..."
    $delegatedSubsValue = $output.value
    $delegatedSubs = $delegatedSubsValue | where-object {$_.tenantId -notmatch $tenantid}
    $delegatedSubs
 }
}