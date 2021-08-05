Connect-AzAccount
Select-AzSubscription 56daa281-46ad-460f-93e6-ee48bf8facec
New-AzSubscriptionDeployment -Name pimapproversdepl `
                 -Location centralus `
                 -TemplateFile "'C:\Users\meolsen\OneDrive - Microsoft\Documents\LH_test\PIM-approvers-sub\delegatedResourceManagement-eligible-authorizations-managing-tenant-approvers.json'" `
                 -TemplateParameterFile "'C:\Users\meolsen\OneDrive - Microsoft\Documents\LH_test\PIM-approvers-sub\delegatedResourceManagement-eligible-authorizations-managing-tenant-approvers.parameters.json'" `
                 -Verbose
