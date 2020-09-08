<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ObjectID
)

Write-Output $("Getting all Azure AD Groups")
$allGroups = Get-AzureADGroup -All $true

$totalGroups = $allGroups.count
$currentGroup = 0
$foundGroups = @()

foreach($group in $allGroups){
    $currentGroup++
    $percentComplete = ($currentGroup / $totalGroups) * 100
    $foundGroupsCount = $foundGroups.count
    Write-Progress -PercentComplete $percentComplete `
        -Activity "Searching..." `
        -Status "($currentGroup / $total) found $foundGroupsCount groups"
    $groupMembers = $group | Get-AzureADGroupMember
    if($groupMembers.ObjectId -contains $ObjectID){
        $foundGroups += $group
        Write-Output $("Found membership in group id: " + $group.ObjectId + " - " + $group.DisplayName)
    }
}