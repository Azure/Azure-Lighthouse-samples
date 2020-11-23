#Connect to AzureAD:
                Install-module AzureADPreview -Force
                $Cred = Get-Credential
                Connect-AzureAD -Credential $Cred

#Get Azure Resources 
                Get-AzureADMSPrivilegedResource -ProviderId "azureResources"
                Get-AzureADMSPrivilegedResource -ProviderId "azureResources" -Filter "type eq 'subscription'"

#Get Role Definitions 
                Get-AzureADMSPrivilegedRoleDefinition -ProviderId "azureResources" -ResourceId e5e7d29d-5465-45ac-885f-4716a5ee74b5

#Get Role Assignments
                Get-AzureADMSPrivilegedRoleAssignment -ProviderId "azureResources" -ResourceId e5e7d29d-5465-45ac-885f-4716a5ee74b5

                Get-AzureADMSPrivilegedRoleAssignment -ProviderId "azureResources" -ResourceId e5e7d29d-5465-45ac-885f-4716a5ee74b5 -Filter "roleDefinitionId eq '8b4d1d51-08e9-4254-b0a6-b16177aae376'"
                
                Filters:
                                -Filter "roleDefinitionId eq '8b4d1d51-08e9-4254-b0a6-b16177aae376'"
                                -Filter "roleDefinitionId eq '8b4d1d51-08e9-4254-b0a6-b16177aae376' and assignmentState eq 'Active'"

#Create Role Assignment Eligible

                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                $schedule.Type = "Once"
                $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                $schedule.endDateTime = (Get-date).AddDays(7).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'azureResources' -ResourceId 'e5e7d29d-5465-45ac-885f-4716a5ee74b5' -RoleDefinitionId '8b4d1d51-08e9-4254-b0a6-b16177aae376' -SubjectId 'd4946569-3f26-43ba-a96d-0790b750ad31' -Type 'AdminAdd' -AssignmentState 'Eligible' -Schedule $schedule

#Activate eligible assignment
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                $schedule.Type = "Once"
                $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                $schedule.endDateTime = (Get-date).AddHours(2).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'azureResources' -ResourceId 'e5e7d29d-5465-45ac-885f-4716a5ee74b5' -RoleDefinitionId '8b4d1d51-08e9-4254-b0a6-b16177aae376' -SubjectId 'd4946569-3f26-43ba-a96d-0790b750ad31' -Type 'UserAdd' -AssignmentState 'Active' -Schedule $schedule -Reason "Test"
