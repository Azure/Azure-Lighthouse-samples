# Scenario: As a customer, I need to validate I have the appropriate permissions (Owner) on the subscriptions/resource groups I want to delegate

$subid = "insert SubscriptionId here"

$context = Get-AzContext
Write-Host -nonewline "The current user ($($context.Account.Id)) "

# Select subscription if current user has access
try
{
    select-azsubscription -subscriptionId $subid -ErrorAction Stop > $null
}
 
catch
{
    Write-Output "does not have access, or the SubscriptionId ($subid) is invalid."
    exit
}

# Get user's roledefintions 
$roles = Get-AzRoleAssignment -SignInName $context.Account.Id -ExpandPrincipalGroups 

# Check if the user is an owner of the subscription
foreach($role in $roles)
{
    if ($role.RoleDefinitionName -eq "Owner") {
        Write-Output "is an owner."
        exit
    }
}

Write-Output "is not an owner."