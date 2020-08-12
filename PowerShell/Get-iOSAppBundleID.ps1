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
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]
    $AppID
)

$req = Invoke-RestMethod -Method Post -Uri "https://itunes.apple.com/lookup?id=$AppID"
$bundleID = $req.results[0].bundleId

Write-Output $($req.results[0].trackName + " - " + $bundleID)
$bundleID | Set-Clipboard
Write-Output $("Bundle ID saved to clipboard")