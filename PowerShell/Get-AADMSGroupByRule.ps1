<#
.SYNOPSIS
    Find a list of dyanmic groups containing a string in their rule.
.DESCRIPTION
    Search all dynamic groups rules for a substring. Use this to search by serial number
    for device rules for example.
.EXAMPLE
    PS C:\> .\Get-AADMSGroupByRule.ps1 -SearchTerm "*DMRZKTCXMF3M*"
    Returns a list of all groups which contain the specified serial number.
.INPUTS
    String - SearchTerm
    A logical search term to be used in a -like comparison. Case counts!
.OUTPUTS
    Object array of groups which match the search term
.NOTES
    This script assumes you are already connected to AzureAD
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SearchTerm
)

Get-AzureADMSGroup -All $true | `
    Where-Object {$_.GroupTypes -eq "DynamicMembership"} | `
    Where-Object{$_.MembershipRule -like $SearchTerm}